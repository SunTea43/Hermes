module WhatsappBot
  class SkillAuthorization
    class NotAuthorized < StandardError; end

    READ_SKILLS = %w[
      consultar_inventario
      listar_stock_bajo
      consultar_resumen_ventas
    ].freeze

    OPERATOR_MODULES = {
      "registrar_venta" => "sales",
      "registrar_compra" => "purchases"
    }.freeze

    class << self
      def authorize!(user:, business:, skill:)
        role, modules = role_and_modules(user, business)

        return true if %w[owner manager].include?(role)
        return true if %w[operator viewer].include?(role) && READ_SKILLS.include?(skill)
        return true if role == "operator" && operator_allowed?(skill, modules)

        raise NotAuthorized, "#{role || 'unassigned'} cannot execute #{skill}"
      end

      def authorize(user:, business:, skill:)
        authorize!(user: user, business: business, skill: skill)
        true
      rescue NotAuthorized
        false
      end

      private

      def role_and_modules(user, business)
        assignment = user.role_assignments.find_by(
          business: business,
          status: "active"
        )
        modules = assignment&.assigned_modules.to_s.split(",").map(&:strip)
        [ assignment&.role, modules ]
      end

      def operator_allowed?(skill, modules)
        required_module = OPERATOR_MODULES[skill]
        required_module.present? && modules.include?(required_module)
      end
    end
  end
end
