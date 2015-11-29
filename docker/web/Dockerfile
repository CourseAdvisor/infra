FROM nginx

ADD config/courseadvisor.conf /etc/nginx/conf.d/
RUN rm /etc/nginx/conf.d/default.conf

ADD config/nginx-start.sh /opt/bin/nginx-start.sh
RUN chmod u=rwx /opt/bin/nginx-start.sh

ENTRYPOINT ["/opt/bin/nginx-start.sh"]
CMD ["nginx", "-g", "daemon off;"]
