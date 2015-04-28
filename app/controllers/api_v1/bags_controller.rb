require_relative '../../../app/presenters/api_v1/bag_presenter'

class ApiV1::BagsController < ApplicationController
  include Authenticate
  include Pagination

  uses_pagination :index

  def index
    raw_bags = Bag.page(@page).per(@page_size)
    @bags = raw_bags.collect do |bag|
      ApiV1::BagPresenter.new(bag)
    end

    output = {
      :count => @bags.size,
      :next => link_to_next_page(raw_bags.total_count),
      :previous => link_to_previous_page,
      :results => @bags
    }

    render json: output
  end

  def show
    bag = Bag.find_by_uuid(params[:uuid])
    if bag.nil?
      render nothing: true, status: 404
    else
      @bag = ApiV1::BagPresenter.new(bag)
      render json: @bag
    end
  end


  # This method is internal
  def create
    # Ensure that the request comes from the local node.
    if @requester.namespace != Rails.configuration.local_namespace
      render json: "Only allowed by local node.", status: 403
      return
    end

    expected_params = [:bag_type, :rights, :interpretive, :uuid,
      :local_id, :size, :version, :ingest_node, :admin_node,
      :replicating_nodes, :first_version_uuid, :fixities
    ]

    unless expected_params.all? {|param| params.has_key?(param)}
      render json: "Illegal bag, missing parameters", status: 400
      return
    end

    case params[:bag_type]
      when "D"
        bag = DataBag.new
      when "R"
        bag = RightsBag.new
      when "I"
        bag = InterpretiveBag.new
      else
        render json: "Invalid bag_type, must be one of D|R|I", status: 400
        return
    end

    bag.rights_bags = RightsBag.where(uuid: params[:rights])
    bag.interpretive_bags = InterpretiveBag.where(uuid: params[:interpretive])
    bag.uuid = params[:uuid]
    bag.local_id = params[:local_id]
    bag.size = params[:size]         #ActiveRecord should convert strings to ints for us
    bag.version = params[:version]   #ActiveRecord should convert strings to ints for us
    bag.ingest_node = Node.find_by_namespace(params[:ingest_node])
    bag.admin_node = Node.find_by_namespace(params[:admin_node])
    bag.replicating_nodes = Node.where(:namespace => params[:replicating_nodes])
    bag.version_family = VersionFamily.find_by_uuid(params[:first_version_uuid])
    bag.version_family ||= VersionFamily.new(uuid: params[:first_version_uuid])

    params[:fixities].each_key do |algorithm|
      fixity_check = FixityCheck.new
      fixity_check.fixity_alg = FixityAlg.find_by_name(algorithm)
      fixity_check.value = params[:fixities][algorithm]
      bag.fixity_checks << fixity_check
    end

    if bag.save
      render nothing: true, content_type: "application/json", status: 201, location: api_v1_bag_url(bag)
    else
      if bag.errors[:uuid].include?("has already been taken")
        render json: "Duplicate bag", status: 409
      else
        render json: "Invalid bag", status: 400
      end
    end

  end


  # This method is internal
  def update
    # Ensure that the request comes from the local node.
    if @requester.namespace != Rails.configuration.local_namespace
      render json: "Only allowed by local node.", status: 403
      return
    end

    case params[:bag_type]
      when "D"
        bag = DataBag.new
      when "R"
        bag = RightsBag.new
      when "I"
        bag = InterpretiveBag.new
      else
        render json: "Invalid bag_type, must be one of D|R|I", status: 400
        return
    end

    bag = Bag.find_by_uuid(params[:uuid])
    if bag.nil?
      head 404
      return
    end

    bag.local_id = params[:local_id]
    bag.admin_node = Node.find_by_namespace(params[:admin_node])
    bag.replicating_nodes = Node.where(:namespace => params[:replicating_nodes])
    bag.rights_bags = RightsBag.where(uuid: params[:rights])
    bag.interpretive_bags = InterpretiveBag.where(uuid: params[:interpretive])

    params[:fixities].each do |algorithm|
      bag.fixity_checks << FixityCheck.find_or_create_by(
          :bag_id => bag.id,
          :fixity_alg_id => FixityAlg.find_by_name(algorithm).id,
          :value => params[:fixities][algorithm]
      )
    end

    if bag.save
      render json: ApiV1::BagPresenter.new(bag), status: 200
    else
      head 400
    end

  end


  # This method is internal
  def _update
    if @requester.namespace != Rails.configuration.config.local_namespace
      render json: "Only allowed by local node.", status: 403
    else
      case params[:bag][:bag_type]
      when "D"
        bag = DataBag.find_by_uuid!(params[:bag][:uuid])
        bag.rights_bags = RightsBag.where(:uuid => params[:bag][:rights])
        bag.brightening_bags = InterpretiveBag.where(:uuid => params[:bag][:interpretive])
      when "R"
        bag = RightsBag.new
      when "I"
        bag = InterpretiveBag.new
      else
        throw TypeError, "illegal bag type #{params[:bag][:bag_type]}"
      end

      bag = Bag.find_by_uuid!(params[:bag][:uuid])
      bag.local_id = params[:bag][:local_id]
      bag.admin_node = Node.find_by_namespace(params[:bag][:admin_node])
      bag.replicating_nodes = Node.where(:namespace => params[:bag][:replicating_nodes_nodes])

      params[:bag][:fixities].each do |check|
        bag.fixity_checks << FixityCheck.find_or_create_by(
          :bag_id => bag.id,
          :fixity_alg_id => FixityAlg.find_by_name(check[:fixity_alg]).id,
          :value => check[:fixity_value]
        )
      end

      bag.save
      render json: ApiV1::BagPresenter.new(bag)
    end
  end

  private
  def sanitize_params
    params[:bag][:size] = params[:bag][:size].to_i
    params[:bag][:version] = params[:bag][:version].to_i
  end


end