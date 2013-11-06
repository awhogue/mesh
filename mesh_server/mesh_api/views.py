import json, re
from django.http import HttpResponse, HttpResponseRedirect, Http404
from django.shortcuts import render_to_response
from django.template import RequestContext
from django.contrib.auth import authenticate
from mesh_api.models import SimpleUser


# private
def create_or_find_user(name, major, minor):
  try:
    user = SimpleUser.objects.get(name__exact=name)
  except SimpleUser.DoesNotExist:
    user = SimpleUser(name=name, major=major, minor=minor)
    user.save()
  return user
    

# Register a new phone on the system.
# TODO: make this a POST
def register(request):
  name = request.GET['name']
  major = request.GET['major']
  minor = request.GET['minor']
  user = create_or_find_user(name, major, minor)
  print 'user: ', user
  return HttpResponse(user.json())

# Given a list of {major,minor} ids, return the users associated with those IDs.
# The "ids" parameter is a sequence of "major,minor" entries, separated by semi-colons.
# E.g. /find_users/1,2;8,10;37,21
def find_users(request, id_param):
  ids = [id.split(',') for id in id_param.split(';')]
  user_jsons = {}
  for id in ids:
    try:
      user = SimpleUser.objects.get(major=id[0], minor=id[1])
      user_jsons[','.join(id)] = user.raw_json()
    except SimpleUser.DoesNotExist:
      print 'find_users: Client requested an unknown major,minor pair: %s,%s' % (id[0], id[1])
      user_jsons[','.join(id)] = { }

  return HttpResponse(json.dumps(user_jsons))
      
      
      
