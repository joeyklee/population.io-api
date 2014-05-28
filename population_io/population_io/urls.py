from django.conf.urls import patterns, include, url
import api.urls

#from django.contrib import admin
#admin.autodiscover()

urlpatterns = patterns('',
    url(r'^api/', include(api.urls)),

    # Examples:
    # url(r'^$', 'population_io.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),
    # url(r'^admin/', include(admin.site.urls)),
)
