require 'aws-sdk'
require 'assumer'
require_relative 'loggable'

VERSION = '1.0.0'
# Takes a snapshot of an instance in AWS
class Selfie
  include Loggable
  def initialize(options)
    @region = options.fetch(:region)
    @target_account = options.fetch(:target_account)
    @target_role = options.fetch(:target_role)
    @target_instance_list = options.fetch(:target_instance_list)
    @forensic_account = options.fetch(:forensic_account)
    @control_account = options.fetch(:control_account)
    @control_role = options.fetch(:control_role)
    @username = options.fetch(:username)
    @bucket = options.fetch(:bucket)
    @ticket_id = options.fetch(:ticket_id)
    @profile = options.fetch(:profile)
  end

  def assume(account:)
    role = "arn:aws:iam::#{@control_account}:role/#{@control_role}"
    log.info "Assuming role into #{role}"
    first_hop = Assumer::Assumer.new(
      profile: @profile,
      region: @region,
      account: @control_account,
      role: role,
      serial_number: "arn:aws:iam::#{@control_account}:mfa/#{@username}")
    role = "arn:aws:iam::#{account}:role/#{@target_role}"
    log.info "Assuming role into #{role}"
    Assumer::Assumer.new(
      region: @region,
      account: account,
      role: role,
      credentials: first_hop).assume_role_credentials
  end

  def start_snapshots(ec2:)
    snapshots = {}
    reservations = ec2.describe_instances(instance_ids: @target_instance_list).reservations
    reservations.each do |reservation|
      reservation.instances.each do |instance|
        instance.block_device_mappings.each do |device|
          description = "#{@ticket_id} | #{instance.instance_id} | #{device.device_name} | #{device.ebs.volume_id}"
          log.info "Taking snapshot: #{description}"
          snap = ec2.create_snapshot(volume_id: device.ebs.volume_id,
                                     description: description)
          snapshots[snap.snapshot_id] = description
        end
      end
    end
    snapshots
  end

  def wait(ec2:, snapshot_ids:)
    while !snapshot_ids.empty? do
      sleep 10
      snapshots = ec2.describe_snapshots(snapshot_ids: snapshot_ids).snapshots
      log.info "Account has #{snapshot_ids.count} snapshots pending"
      snapshots.each do |s|
        log.info "#{s.snapshot_id} is #{s.state}, #{s.progress}"
        snapshot_ids.delete(s.snapshot_id) if s.state == 'completed' || s.state == 'error'
      end
    end
  end

  def add_perms(ec2:, snapshot_ids:)
    snapshot_ids.each do |s|
      log.info "Adding #{s} perms from #{@forensic_account}"
      perms = { add: [{ user_id: @forensic_account }] }
      ec2.modify_snapshot_attribute(snapshot_id: s,
                                    attribute: 'createVolumePermission',
                                    create_volume_permission: perms)
    end
  end

  # AWS has a limit of 5 simultanious snapshot copies (for us-west-2 at least)
  def copy_snapshot(ec2:, snapshots:)
    log.info "Copying #{snapshots.keys.join}"
    new_snapshot_ids = []
    snapshots.each do |snapshot_id, description|
      snapshot = ec2.copy_snapshot(source_region: @region,
                                   source_snapshot_id: snapshot_id,
                                   description: "IR Copy | #{description}",
                                   destination_region: @region)
      new_snapshot_ids << snapshot.snapshot_id
    end
    new_snapshot_ids
  end

  def snap
    log.info "Target account: #{@target_account}"
    creds = assume(account: @target_account)
    ec2 = Aws::EC2::Client.new(region: @region, credentials: creds)

    # create snapshot of instances
    snapshots = start_snapshots(ec2: ec2)
    wait(ec2: ec2, snapshot_ids: snapshots.keys)
    add_perms(ec2: ec2, snapshot_ids: snapshots.keys)

    creds = assume(account: @forensic_account)
    ec2 = Aws::EC2::Client.new(region: @region, credentials: creds)
    new_snapshot_ids = copy_snapshot(ec2: ec2, snapshots: snapshots)
    wait(ec2: ec2, snapshot_ids: new_snapshot_ids)
  end
end
