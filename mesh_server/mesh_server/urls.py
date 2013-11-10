from django.conf.urls import patterns, include, url

# Uncomment the next two lines to enable the admin:
# from django.contrib import admin
# admin.autodiscover()

urlpatterns = patterns('mesh_api.views',
                       url(r'^find_users/?(?P<id_param>[\d,;]+)?', 'find_users'),
                       url(r'^register', 'register'),
                       url(r'', 'home'),
    # Examples:
    # url(r'^$', 'mesh_server.views.home', name='home'),
    # url(r'^mesh_server/', include('mesh_server.foo.urls')),

    # Uncomment the admin/doc line below to enable admin documentation:
    # url(r'^admin/doc/', include('django.contrib.admindocs.urls')),

    # Uncomment the next line to enable the admin:
    # url(r'^admin/', include(admin.site.urls)),
)
