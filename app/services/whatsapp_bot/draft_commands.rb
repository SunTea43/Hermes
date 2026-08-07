module WhatsappBot
  # Parses draft-editing commands used during purchase/sale review.
  module DraftCommands
    REMOVE = /\A(?:quitar|eliminar|borra(?:r)?)\s+(?:el\s+|la\s+|ítem\s+|item\s+)?(.+)\z/i
    CHANGE_PRICE = /\Acambiar\s+precio\s+(.+?)\s+(?:a\s+)?\$?([\d.,]+)\z/i
    CHANGE_QTY = /\Acambiar\s+(?:cantidad|cant\.?)\s+(.+?)\s+(?:a\s+)?([\d.,]+)\z/i
    SUPPLIER = /\Aproveedor\s+(.+)\z/i
    CUSTOMER = /\Acliente\s+(.+)\z/i

    module_function

    def parse(message)
      text = message.to_s.strip
      return nil if text.blank?

      if (match = text.match(REMOVE))
        return { action: :remove, query: match[1].strip }
      end

      if (match = text.match(CHANGE_PRICE))
        return { action: :change_price, query: match[1].strip, value: match[2].tr(",", ".").to_d }
      end

      if (match = text.match(CHANGE_QTY))
        return { action: :change_quantity, query: match[1].strip, value: match[2].tr(",", ".").to_d }
      end

      if (match = text.match(SUPPLIER))
        return { action: :set_supplier, value: match[1].strip }
      end

      if (match = text.match(CUSTOMER))
        return { action: :set_customer, value: match[1].strip }
      end

      nil
    end

    def apply(draft, command)
      draft = draft.to_h.with_indifferent_access
      items = Array(draft[:items]).map { |item| item.to_h.with_indifferent_access }

      case command[:action]
      when :remove
        filtered = remove_items(items, command[:query])
        return [ :not_found, draft ] if filtered.size == items.size

        draft[:items] = filtered
        [ :ok, draft ]
      when :change_price
        return [ :invalid, draft ] unless command[:value].positive?

        updated, found = update_item(items, command[:query]) { |item|
          item[:unit_price] = command[:value]
          item[:line_total] = item[:quantity].to_d * item[:unit_price].to_d
        }
        return [ :not_found, draft ] unless found

        draft[:items] = updated
        [ :ok, draft ]
      when :change_quantity
        return [ :invalid, draft ] unless command[:value].positive?

        updated, found = update_item(items, command[:query]) { |item|
          item[:quantity] = command[:value]
          item[:line_total] = item[:quantity].to_d * item[:unit_price].to_d
        }
        return [ :not_found, draft ] unless found

        draft[:items] = updated
        [ :ok, draft ]
      when :set_supplier
        draft[:supplier_name] = command[:value]
        [ :ok, draft ]
      when :set_customer
        draft[:customer_name] = command[:value]
        [ :ok, draft ]
      else
        [ :unknown, draft ]
      end
    end

    def remove_items(items, query)
      if query.match?(/\A\d+\z/)
        index = query.to_i - 1
        return items.reject.with_index { |_, i| i == index }
      end

      needle = query.downcase
      items.reject { |item| item[:product_name].to_s.downcase.include?(needle) }
    end

    def update_item(items, query)
      needle = query.downcase
      found = false
      updated = items.map { |item|
        if item[:product_name].to_s.downcase.include?(needle)
          found = true
          yield(item)
        end
        item
      }
      [ updated, found ]
    end
    private_class_method :remove_items, :update_item
  end
end
