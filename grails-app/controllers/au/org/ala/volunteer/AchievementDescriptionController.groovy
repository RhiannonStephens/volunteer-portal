package au.org.ala.volunteer

import au.org.ala.web.AlaSecured
import grails.converters.JSON
import org.springframework.web.multipart.MultipartFile
import org.springframework.web.multipart.MultipartHttpServletRequest

import static grails.async.Promises.*
import static org.springframework.http.HttpStatus.*
import grails.transaction.Transactional

@AlaSecured("ROLE_VP_ADMIN")
class AchievementDescriptionController {

    static allowedMethods = [save: "POST", update: "PUT", delete: "DELETE", uploadBadgeImage: "POST", award: "POST", awardAll: "POST", enable: "POST"]

    def achievementService
    def userService
    
    def index(Integer max) {
        params.max = Math.min(max ?: 10, 100)
        respond AchievementDescription.list(params), model: [achievementDescriptionInstanceCount: AchievementDescription.count()]
    }

    def show(AchievementDescription achievementDescriptionInstance) {
        if (!achievementDescriptionInstance) {
            notFound()
        } else {
            redirect action: 'edit', id: achievementDescriptionInstance.id
        }
    }
    
    def create() {
        respond new AchievementDescription()
    }

    def save(AchievementDescription achievementDescriptionInstance) {
        if (achievementDescriptionInstance == null) {
            notFound()
            return
        }

        if (achievementDescriptionInstance.hasErrors()) {
            respond achievementDescriptionInstance.errors, view: 'create'
            return
        }

        achievementDescriptionInstance.save flush: true

        cleanBadges()

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.created.message', args: [message(code: 'achievementDescription.label', default: 'AchievementDescription'), achievementDescriptionInstance.id])
                redirect achievementDescriptionInstance
            }
            '*' { respond achievementDescriptionInstance, [status: CREATED] }
        }
    }

    def edit(AchievementDescription achievementDescriptionInstance) {
        respond achievementDescriptionInstance
    }

    def editTest(AchievementDescription achievementDescriptionInstance) {

        def userId = params.userId ?: userService.currentUserId
        def user = User.findByUserId(userId)
        def eval = achievementService.evaluateAchievement(achievementDescriptionInstance, userId)
        def cheevMap = [(user.displayName): eval]

        withFormat {
            form html {
                render view: 'editTest', model: [achievementDescriptionInstance: achievementDescriptionInstance, cheevMap: cheevMap, displayName: user?.displayName, userId: userId]
            }
            '*' { respond((Object)cheevMap, status: OK) }
        }
    }

    def update(AchievementDescription achievementDescriptionInstance) {
        if (achievementDescriptionInstance == null) {
            notFound()
            return
        }

        if (achievementDescriptionInstance.hasErrors()) {
            respond achievementDescriptionInstance.errors, view: 'edit'
            return
        }

        achievementDescriptionInstance.save flush: true

        cleanBadges()

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.updated.message', args: [message(code: 'achievementDescription.label', default: 'AchievementDescription'), achievementDescriptionInstance.id])
                redirect action: 'edit', id: achievementDescriptionInstance.id
            }
            '*' { respond achievementDescriptionInstance, [status: OK] }
        }
    }

    def delete(AchievementDescription achievementDescriptionInstance) {

        if (achievementDescriptionInstance == null) {
            notFound()
            return
        }

        achievementDescriptionInstance.delete flush: true

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.deleted.message', args: [message(code: 'achievementDescription.label', default: 'AchievementDescription'), achievementDescriptionInstance.id])
                redirect action: "index", method: "GET"
            }
            '*' { render status: NO_CONTENT }
        }
    }

    protected void notFound() {
        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'default.not.found.message', args: [message(code: 'achievementDescription.label', default: 'AchievementDescription'), params.id])
                redirect action: "index", method: "GET"
            }
            '*' { render status: NOT_FOUND }
        }
    }

    def run(Long achievementId, Long userId, Long taskId) {
        achievementService.evaluateAchievement(AchievementDescription.get(achievementId), User.get(userId), taskId)
    }

    def uploadBadgeImage() {
        def id = params.long("id");
        def achievement = id ? AchievementDescription.get(id) : null


        def json = [:]
        def status = OK
        if (request instanceof MultipartHttpServletRequest) {
            MultipartFile f = ((MultipartHttpServletRequest) request).getFile('imagefile')

            if (f != null && f.size > 0) {
                def allowedMimeTypes = ['image/jpeg', 'image/png']
                if (!allowedMimeTypes.contains(f.getContentType())) {
                    json.put("error", "Image must be one of: ${allowedMimeTypes}")
                    status = BAD_REQUEST
                } else {
                    boolean result
                    String filename = UUID.randomUUID().toString() + '.' + contentTypeToExtension(f.contentType)
                    result = uploadToLocalPath(f, filename)

                    if (result) {
                        json.put('filename', filename)
                        if (achievement) {
                            achievement.badge = filename
                            achievement.save(flush: true)
                        }
                    } else {
                        json.put('error', "Failed to upload image. Unknown error!")
                        status = INTERNAL_SERVER_ERROR
                    }
                }
            } else {
                json.put('error', "Please select a file!")
                status = BAD_REQUEST
            }
        } else {
            json.put('error', "Form must be multipart file!")
            status = BAD_REQUEST
        }

        respond((Object)json, status: status.value())
    }

    def awards(AchievementDescription achievementDescriptionInstance) {
        //def evals = achievementDescriptionInstance.awards*.user.collectEntries { [ (it.userId) : achievementService.evaluateAchievement(achievementDescriptionInstance, it, null)] }
        respond achievementDescriptionInstance//, [model: [evals: evals]]
    }

    def checkAward(AchievementDescription achievementDescriptionInstance) {
        def ids = (params.list('ids[]') ?: [])*.toLong()
        def users = User.findAllByIdInList(ids)
        def result = users.collectEntries { [ (it.userId) : achievementService.evaluateAchievement(achievementDescriptionInstance, it.userId) ] }
        render result as JSON
    }

    def awardAll(AchievementDescription achievementDescriptionInstance) {

        def awardedUsers = achievementDescriptionInstance.awards*.user*.id.toList()
        def eligibleUsers = User.withCriteria {
            if (awardedUsers) {
                not { inList('id', awardedUsers) }
            }
            projections {
                property('userId')
            }
        }

        def awards = eligibleUsers
                        .findAll { achievementService.evaluateAchievement(achievementDescriptionInstance, it) }
                        .collect { new AchievementAward(user: User.findByUserId(it), achievement: achievementDescriptionInstance, awarded: new Date()) }

//        AchievementAward.saveAll(awards)
        awards*.save()

        awards.each { notify(AchievementService.ACHIEVEMENT_AWARDED, it) }

        request.withFormat {
            form multipartForm {
                flash.message = awards.collect { message(code: 'achievement.awarded.message', args: [achievementDescriptionInstance.name, it.user.displayName]) }.join('<br/>')
                redirect action: 'awards', id: achievementDescriptionInstance.id
            }
            '*' { respond awards, [status: OK] }
        }
    }

    def award(AchievementDescription achievementDescriptionInstance) {

        def userId = params.userId
        def user = User.findByUserId(userId)

        if (!user) {
            flash.message = message(code: 'default.not.found.message', args: [message(code: 'user.label', default: 'User'), userId])
            redirect action: 'awards', id: achievementDescriptionInstance.id
            return
        }

        def award = new AchievementAward(user: user, achievement: achievementDescriptionInstance, awarded: new Date())
        award.save flush: true

        notify(AchievementService.ACHIEVEMENT_AWARDED, award)

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'achievement.awarded.message', args: [achievementDescriptionInstance.name, user.displayName])
                redirect action: 'awards', id: achievementDescriptionInstance.id
            }
            '*' { respond award, [status: OK] }
        }
    }

    def unawardAll(AchievementDescription achievementDescriptionInstance) {
        def awards = AchievementAward.findAllByAchievement(achievementDescriptionInstance)
        log.info("Removing awarded achievements: ${awards.join('\n')}")

        AchievementAward.deleteAll(awards)

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'achievement.removed.message', args: [achievementDescriptionInstance.name, awards*.user*.displayName])
                redirect action: 'awards', id: achievementDescriptionInstance.id
            }
            '*' { render status: NO_CONTENT.value() }
        }
    }

    def unaward(AchievementDescription achievementDescriptionInstance) {
        def awardIds = params.list('ids[]')*.toLong()
        def awards = AchievementAward.findAllByIdInListAndAchievement(awardIds, achievementDescriptionInstance)
        log.info("Removing awarded achievements: ${awards.join('\n')}")

        AchievementAward.deleteAll(awards)

        request.withFormat {
            form multipartForm {
                flash.message = message(code: 'achievement.removed.message', args: [achievementDescriptionInstance.name, awards*.user*.displayName])
                redirect action: 'awards', id: achievementDescriptionInstance.id
            }
            '*' { render status: NO_CONTENT.value() }
        }
    }

    def findEligibleUsers(AchievementDescription achievementDescriptionInstance) {
        // todo search Atlas User Details
        def term = params.term
        def filter = params.boolean('filter', true)
        def ineligible = filter ? achievementDescriptionInstance.awards*.user*.userId : []
        def search = "%${term}%"
        def users = User.withCriteria {
            or {
                ilike 'displayName', search
                ilike 'email', search
            }
            if (ineligible) {
                not {
                    inList 'userId', ineligible
                }
            }
            maxResults 20
            order "displayName", "desc"
        }

        render users as JSON
    }

    def enable(AchievementDescription achievementDescriptionInstance) {
        def enabledParam = params.boolean('enabled') ?: false
        achievementDescriptionInstance.enabled = enabledParam
        achievementDescriptionInstance.save(flush: true)
        render status: NO_CONTENT.value()
    }

    private static String contentTypeToExtension(String contentType) {
        switch (contentType.toLowerCase()) {
            case 'image/png':
                return 'png'
            case 'image/jpeg':
                return 'jpg'
            case 'image/gif':
                return 'gif'
            case 'image/webp':
                return 'webp'
            case 'image/tiff':
            case 'image/tiff-fx':
                return 'tiff'
            case 'image/bmp':
            case 'image/x-bmp':
                return 'bmp'
            default:
                return ''
        }
    }

    private boolean uploadToLocalPath(MultipartFile mpfile, String localFile) {
        if (!mpfile) {
            return false
        }

        try {
            def file = new File(achievementService.badgeImageFilePrefix, localFile)
            if (!file.getParentFile().exists() && !file.getParentFile().mkdirs()) {
                throw new RuntimeException("Failed to create institution directories: ${file.getParentFile().getAbsolutePath()}")
            }
            mpfile.transferTo(file);
            return true
        } catch (Exception ex) {
            log.error("Failed to upload achievement badge", ex)
            return false
        }
    }

    private void cleanBadges() {
        def badges = AchievementDescription.withCriteria {
            projections {
                property("badge")
            }
        }
        task {
            achievementService.cleanImageDir(badges)
        }
    }
}
