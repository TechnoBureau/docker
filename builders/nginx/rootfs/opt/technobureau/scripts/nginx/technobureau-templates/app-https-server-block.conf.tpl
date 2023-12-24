{{external_configuration}}

server {
    # Port to listen on, can also be set in IP:PORT format
    {{https_listen_configuration}}

    root {{document_root}};

    {{server_name_configuration}}

    ssl_certificate      certs/server.crt;
    ssl_certificate_key  certs/server.key;

    {{acl_configuration}}

    {{additional_configuration}}

    include  "/opt/technobureau/nginx/conf/technobureau/*.conf";
}
