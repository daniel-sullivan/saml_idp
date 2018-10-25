module SamlIdp
  class NameIdFormatter
    attr_accessor :list
    def initialize(list)
      self.list = (list || {})
    end

    def all

      if split?
        one_one.map { |key_val| build("1.1", key_val[0].to_s, list)[:name] } +
            two_zero.map { |key_val| build("2.0", key_val[0].to_s, list)[:name] }
      else
        list.map { |key_val| build("2.0", key_val[0].to_s, list)[:name] }
      end
    end

    def determinenameid(name_id_details)
      # Check if we have configuration for requested version
      version = name_id_details[0].to_s

      puts name_id_details.inspect
      puts list.inspect

      if !list.key?(version)
        throw "No handler for version #{version} SAML NameID"
      end
      # Check if we have answer for the details
      key = name_id_details[1]

      if !list[version].key?(key.to_sym)
        throw "No handler for property #{key} SAML NameID"
      end

      puts list[version].inspect
      puts list[version][key.to_sym].inspect

      if !name_id_details[2].nil?
        build(version, key, name_id_details[2], true)
      else
        build(version, key, list[version][key.to_sym])
      end

    end

    def chosen
      #Get nameid from request
      #@_name_id ||= saml_request.name_id

      if split?
        version, choose = "1.1", one_one.first
        version, choose = "2.0", two_zero.first unless choose
        version, choose = "2.0", "persistent" unless choose
        build(version, choose)
      else
        choose = list.first || "persistent"
        build("2.0", choose)
      end
    end

    def build(version, name, object, override = false)
      getter = build_getter(object, override)
      {
          name: "urn:oasis:names:tc:SAML:#{version}:nameid-format:#{name.camelize(:lower)}",
          getter: getter
      }
    end
    private :build

    def build_getter(getter_val, override = false)
      if getter_val.respond_to?(:call)
        getter_val
      elsif override
        def getter_val.call(ignored)
          self.to_s
        end

        getter_val
      else
        ->(p) { p.public_send getter_val.to_s }
      end
    end
    private :build_getter

    def split?
      list.is_a?(Hash) && (list.key?("2.0") || list.key?("1.1"))
    end
    private :split?

    def one_one
      list["1.1"] || {}
    rescue TypeError
      {}
    end
    private :one_one

    def two_zero
      list["2.0"] || {}
    rescue TypeError
      {}
    end
    private :two_zero
  end
end

