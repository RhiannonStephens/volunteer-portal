<style>
    section#footer .footer-brand,
    section#footer .footer-brand:hover,
    .navbar-brand,
    .navbar-brand:hover,
    .digivol-tab img,
    body .navbar .navbar-brand,
    body .navbar .navbar-brand:hover,
    body .btn-primary,
    body .btn-primary:hover,
    body .btn-primary:focus,
    body .btn-primary:active,
    body .btn-primary.active,
    body .label,
    .progress .progress-bar-transcribed,
    .key.transcribed,
    .pagination > .active > span,
    .pagination > .active > span:hover,
    .transcription-actions .btn.btn-next {
        background-color: <g:pageProperty name="page.primaryColour" default="#d5502a"/>;
    }
    .progress .progress-bar-success {
        background-color: rgba( <cl:hexToRbg hex="${g.pageProperty(name:"page.primaryColour", default:"#d5502a")}"/>, .5 );
    }

    body .navbar, .pagination > .active > span,
    .pagination > .active > span:hover {
        border-color: <g:pageProperty name="page.primaryColour" default="#d5502a"/>;
    }

    body .badge,
    body .badge:hover,
    .pagination > li > a {
        color: <g:pageProperty name="page.primaryColour" default="#d5502a"/>;
}
</style>