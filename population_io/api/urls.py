from django.conf.urls import patterns, include, url
from django.conf import settings
from api import views



API_VERSION_PREFIX = r'1.0/'
WP_RANK_PREFIX = r'wp-rank/'
DATE_PATTERN = lambda name: r'(?P<%s>\d{4}-\d{2}-\d{2})/' % name
PERSON_PATH = DATE_PATTERN('dob') + r'/(?P<gender>[a-z]+)/(?P<country>[a-z]|%20+)/'


urlpatterns = [
    # /api/1.0/meta/countries/
    url(API_VERSION_PREFIX + r'meta/countries/', views.list_countries),

    # /api/1.0/wp-rank/
    url(API_VERSION_PREFIX + WP_RANK_PREFIX + PERSON_PATH + r'today/', views.wprank_today),
    url(API_VERSION_PREFIX + WP_RANK_PREFIX + PERSON_PATH + r'on/' + DATE_PATTERN('date'), views.wprank_by_date),
    url(API_VERSION_PREFIX + WP_RANK_PREFIX + PERSON_PATH + r'aged/(?P<age>.*)/', views.wprank_by_age),
    url(API_VERSION_PREFIX + WP_RANK_PREFIX + PERSON_PATH + r'ago/(?P<offset>.*)/', views.wprank_ago),
    #url(API_PREFIX + WP_RANK_PREFIX + PERSON_PATH + r'in/?P<offset>.*/', views.wprank_ago),
    url(API_VERSION_PREFIX + WP_RANK_PREFIX + PERSON_PATH + r'ranked/(?P<rank>\d+)/', views.wprank_by_rank),

    # /api/1.0/life-expectancy/
    url(API_VERSION_PREFIX + r'life-expectancy/' + PERSON_PATH, views.life_expectancy),

    # /api/docs/ (Swagger documentation)
    url(r'^docs/', include('rest_framework_swagger.urls')),
]
