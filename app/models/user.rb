# Copyright 2014 Mainio Tech Ltd.
#
# @author Antti Hukkanen
# @license See LICENSE (project root)

class User < ActiveRecord::Base
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  # :registerable

  has_many :zone_permissions, dependent: :destroy

  def allowed_zones(zones, project, method)
    if self.has_role?(:admin, project)
      zones
    else
      zones.select { |z| zone_permissions.where(zone_id: z.id, name: method).any? }
    end
  end

  def can_read_zone?(zone)
    has_zone_permission?(zone, :read)
  end

  def can_edit_zone?(zone)
    has_zone_permission?(zone, :edit)
  end

  def can_destroy_zone?(zone)
    has_zone_permission?(zone, :destroy)
  end

  def create_permissions_for_new_zone(zone, project)
    if has_role?(:zone_manager, project)
      zone_permissions.create([
        { zone_id: zone.id, project: project, name: :read },
        { zone_id: zone.id, project: project, name: :edit },
        { zone_id: zone.id, project: project, name: :destroy }
      ])
    end
  end

  private
    def has_zone_permission?(zone, name)
      zone_permissions.where(zone_id: zone.id, name: name).any?
    end
end
