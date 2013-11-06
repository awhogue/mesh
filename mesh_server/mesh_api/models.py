import json
from django.db import models

# Stay simple for now, but someday use django.contrib.auth.models.User
class SimpleUser(models.Model):
  name = models.CharField(max_length=256)
  major = models.PositiveIntegerField()
  minor = models.PositiveIntegerField()
  
  def __unicode__(self):
    return '<%d> {%d,%d} [%s]' % (self.id, self.major, self.minor, self.name)

  def json(self):
    return json.dumps(self.raw_json())

  def raw_json(self):
    return { 'id': self.pk,
             'major': self.major,
             'minor': self.minor,
             'name': self.name,
             }
