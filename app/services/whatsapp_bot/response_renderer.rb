module WhatsappBot
  class ResponseRenderer
    MENU = <<~MSG.strip
      No entendí ese mensaje. Podés escribirme:

      📦 *Ventas*
      • "Vendí 10kg de arroz"
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

      def sale_ask_customer(quantity:, unit_measure:, product_name:, unit_price:, total:)
        "#{format_qty(quantity)}#{unit_measure} de #{product_name} × $#{format_money(unit_price)} = $#{format_money(total)}. ¿A quién? (nombre o 'venta general')"
      end

      def sale_ask_payment_condition(customer_name:)
        "Venta a #{customer_name}. ¿Contado o crédito?"
      end

      def sale_confirm(customer_name:, quantity:, unit_measure:, product_name:, total:, payment_condition:)
        cond_label = payment_condition == "credit" ? "crédito" : "contado"
        "Venta a #{customer_name}: #{format_qty(quantity)}#{unit_measure} #{product_name} = $#{format_money(total)} (#{cond_label}). ¿Confirmo? (sí/no)"
      end

      def sale_recorded(reference_number:, product_name: nil, current_quantity: nil, unit_measure: nil)
        stock = stock_suffix(product_name, current_quantity, unit_measure)
        "✅ #{reference_number} registrada.#{stock}"
      end

      def sale_parse_error
        'No entendí. Ejemplo: "Vendí 10kg de arroz" o "Fiado a María 5kg arroz".'
      end

      def product_not_found(name, in_inventory: true)
        suffix = in_inventory ? " en tu inventario" : ""
        "No encontré el producto \"#{name}\"#{suffix}."
      end

      def purchase_confirm(supplier_name:, product_name:, quantity:, unit_measure:, total:)
        "Compra a #{supplier_name}:\n- #{product_name} #{format_qty(quantity)}#{unit_measure}: $#{format_money(total)}\nTotal: $#{format_money(total)}. ¿Confirmo?"
      end

      def purchase_recorded(reference_number:, product_name: nil, current_quantity: nil, unit_measure: nil)
        stock = stock_suffix(product_name, current_quantity, unit_measure)
        "✅ #{reference_number} registrada.#{stock}"
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
