location ^~ {{location}} {
    alias "{{document_root}}";

    {{acl_configuration}}

    include "/opt/technobureau/nginx/conf/technobureau/protect-hidden-files.conf";
    include "/opt/technobureau/nginx/conf/technobureau/php-fpm.conf";
}

{{additional_configuration}}
