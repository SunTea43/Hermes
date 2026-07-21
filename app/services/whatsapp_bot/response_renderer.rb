module WhatsappBot
  class ResponseRenderer
    MENU = <<~MSG.strip
      No entendí ese mensaje. Puedes escribirme:

      📦 *Ventas*
      • "Vendí 10kg de arroz"
      • "Vendí 10kg arroz y 5lt aceite"
      • "Fiado a María 5kg arroz"

      🛒 *Compras*
      • "Recibí de Juanito: arroz 50kg a $2,000"

      💰 *Pagos*
      • "María pagó $10,000"

      📊 *Inventario*
      • "¿Cuánto arroz me queda?"
      • "¿Qué está bajo?"

      📈 *Reporte*
      • "Reporte del día"
    MSG

    class << self
      def unknown_menu
        MENU
      end

      def sale_ask_customer(quantity: nil, unit_measure: nil, product_name: nil, unit_price: nil, total: nil, items: nil)
        if items.present?
          "#{format_cart_lines(items)}\nTotal: $#{format_money(cart_total(items, total))}. ¿A quién? (nombre o 'venta general')"
        else
          "#{format_qty(quantity)}#{unit_measure} de #{product_name} × $#{format_money(unit_price)} = $#{format_money(total)}. ¿A quién? (nombre o 'venta general')"
        end
      end

      def sale_ask_payment_condition(customer_name:)
        "Venta a #{customer_name}. ¿Contado o crédito?"
      end

      def sale_cart(items:, total: nil)
        <<~MSG.strip
          #{format_cart_lines(items)}
          Total: $#{format_money(cart_total(items, total))}
          Agrega otro producto o escribe *listo* para continuar.
        MSG
      end

      def sale_confirm(customer_name:, payment_condition:, total: nil, items: nil, quantity: nil, unit_measure: nil, product_name: nil)
        cond_label = payment_condition == "credit" ? "crédito" : "contado"
        if items.present?
          <<~MSG.strip
            Venta a #{customer_name}:
            #{format_cart_lines(items)}
            Total: $#{format_money(cart_total(items, total))} (#{cond_label}). ¿Confirmo? (sí/no)
          MSG
        else
          "Venta a #{customer_name}: #{format_qty(quantity)}#{unit_measure} #{product_name} = $#{format_money(total)} (#{cond_label}). ¿Confirmo? (sí/no)"
        end
      end

      def sale_recorded(reference_number:, items: nil, product_name: nil, current_quantity: nil, unit_measure: nil, total: nil)
        lines = [ "✅ #{reference_number} registrada." ]
        if items.present?
          Array(items).each do |item|
            item = item.with_indifferent_access
            next if item[:current_quantity].nil? || item[:product_name].blank?

            lines << " Stock #{item[:product_name]}: #{format_qty(item[:current_quantity])}#{item[:unit_measure]}"
          end
        else
          stock = stock_suffix(product_name, current_quantity, unit_measure)
          lines[0] = "#{lines[0]}#{stock}"
        end
        lines.join
      end

      def sale_parse_error
        'No entendí. Ejemplo: "Vendí 10kg de arroz" o "Vendí 10kg arroz y 5lt aceite".'
      end

      def product_not_found(name, in_inventory: true)
        suffix = in_inventory ? " en tu inventario" : ""
        "No encontré el producto \"#{name}\"#{suffix}."
      end

      def purchase_cart(items:, supplier_name:, total: nil)
        <<~MSG.strip
          Compra a #{supplier_name}:
          #{format_cart_lines(items)}
          Total: $#{format_money(cart_total(items, total))}
          Agrega otro producto o escribe *listo* para confirmar.
        MSG
      end

      def purchase_confirm(supplier_name:, items: nil, product_name: nil, quantity: nil, unit_measure: nil, total: nil)
        if items.present?
          <<~MSG.strip
            Compra a #{supplier_name}:
            #{format_cart_lines(items)}
            Total: $#{format_money(cart_total(items, total))}. ¿Confirmo?
          MSG
        else
          "Compra a #{supplier_name}:\n- #{product_name} #{format_qty(quantity)}#{unit_measure}: $#{format_money(total)}\nTotal: $#{format_money(total)}. ¿Confirmo?"
        end
      end

      def purchase_recorded(reference_number:, items: nil, product_name: nil, current_quantity: nil, unit_measure: nil, total: nil)
        sale_recorded(
          reference_number: reference_number,
          items: items,
          product_name: product_name,
          current_quantity: current_quantity,
          unit_measure: unit_measure,
          total: total
        )
      end

      def purchase_parse_error
        'No entendí. Ejemplo: "Recibí de Juanito: arroz 50kg a $2,000" o agrega varios productos y escribe *listo*.'
      end

      def payment_confirm(customer_name:, remaining:, reference_number:, amount:, new_balance:)
        "#{customer_name} tiene saldo de $#{format_money(remaining)} (#{reference_number}). Abono de $#{format_money(amount)}.\nSaldo pendiente: $#{format_money(new_balance)}. ¿Confirmo?"
      end

      def payment_recorded(customer_name:, remaining:)
        "✅ Pago registrado. Saldo pendiente #{customer_name}: $#{format_money(remaining)}"
      end

      def inventory_item(product_name:, current_quantity:, unit_measure:, minimum_alert_quantity:, low:)
        status = low ? "⚠️" : "✅"
        "#{product_name}: #{format_qty(current_quantity)}#{unit_measure} #{status} (mín. #{format_qty(minimum_alert_quantity)})"
      end

      def inventory_not_found(name)
        "No encontré \"#{name}\" en tu inventario."
      end

      def low_stock_ok
        "✅ Todo el stock está sobre los mínimos."
      end

      def low_stock_list(items)
        lines = items.map { |i|
          "- #{i[:product_name]}: #{format_qty(i[:current_quantity])}#{i[:unit_measure]} (mín. #{format_qty(i[:minimum_alert_quantity])})"
        }
        "⚠️ Productos bajo mínimo:\n#{lines.join("\n")}"
      end

      def daily_report(date:, count:, total:, cash:, credit:, pending_portfolio:, low_stock_count: 0)
        lines = [
          "📊 Resumen del día #{date.strftime('%d/%m')}:",
          "- Ventas: #{count} (total $#{format_money(total)})",
          "  • Contado: $#{format_money(cash)}",
          "  • Crédito: $#{format_money(credit)}",
          "- Cartera total pendiente: $#{format_money(pending_portfolio)}"
        ]
        lines << "⚠️ #{low_stock_count} productos bajo mínimo" if low_stock_count.to_i.positive?
        lines.join("\n")
      end

      def cancelled(kind)
        case kind.to_sym
        when :sale then "Venta cancelada."
        when :purchase then "Compra cancelada."
        when :payment then "Pago cancelado."
        else "#{kind} cancelado."
        end
      end

      def confirm_yes_no
        "Responde 'sí' para confirmar o 'no' para cancelar."
      end

      def ask_cash_or_credit
        "Responde 'contado' o 'crédito'."
      end

      def skill_error(action, errors)
        "No pude #{action}: #{Array(errors).join(', ')}"
      end

      private

      def format_cart_lines(items)
        Array(items).map { |item|
          item = item.with_indifferent_access
          line_total = item[:line_total] || (item[:quantity].to_d * item[:unit_price].to_d)
          "- #{format_qty(item[:quantity])}#{item[:unit_measure]} #{item[:product_name]} = $#{format_money(line_total)}"
        }.join("\n")
      end

      def cart_total(items, total = nil)
        return total if total.present?

        Array(items).sum { |item|
          item = item.with_indifferent_access
          item[:line_total] || (item[:quantity].to_d * item[:unit_price].to_d)
        }
      end

      def stock_suffix(product_name, current_quantity, unit_measure)
        return "" if current_quantity.nil? || product_name.blank?

        " Stock #{product_name}: #{format_qty(current_quantity)}#{unit_measure}"
      end

      def format_qty(value)
        number = value.to_d
        number == number.to_i ? number.to_i.to_s : number.to_s("F")
      end

      def format_money(value)
        number = value.to_d
        number == number.to_i ? number.to_i.to_s : number.to_s("F")
      end
    end
  end
end
