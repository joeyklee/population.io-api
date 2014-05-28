import datetime
from rest_framework.exceptions import ParseError



def _to_int(int_string):
    try:
        return int(int_string)
    except ValueError:
        raise ParseError(detail='Invalid number format given')

def _to_datetime(date_string):
    try:
        return datetime.datetime.strptime(date_string, '%Y-%m-%d')
    except ValueError:
        raise ParseError(detail='Invalid date format given, please use YYYY-MM-DD (e.g. 1952-03-11)')

def _datetime_to_str(datetime_obj):
    return datetime_obj.strftime('%Y-%m-%d')
