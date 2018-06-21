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
      zones.select { |z| zone_permissions.where(zone_id: z.id, name: method, project: project.id).any? }
    end
  end

  def create_permissions_for_new_zone(zone)
    if has_role?(:zone_manager, zone.project)
      zone_permissions.create([
        { zone_id: zone.id, project: zone.project, name: :read },
        { zone_id: zone.id, project: zone.project, name: :edit },
        { zone_id: zone.id, project: zone.project, name: :destroy }
      ])
    end
  end

  def has_zone_permission?(zone, name)
    zone_permissions.where(zone_id: zone.id, name: name, project_id: zone.project_id).any?
  end

  def send_welcome_mail(adder)
    token = set_reset_password_token
    WelcomeMailer.added(adder, self, token).deliver
  end
end
