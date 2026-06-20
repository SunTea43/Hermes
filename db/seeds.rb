puts "Limpiando datos previos..."
InventoryMovement.delete_all
Inventory.delete_all
Payment.delete_all
SalesOrderItem.delete_all
SalesOrder.delete_all
PurchaseOrderItem.delete_all
PurchaseOrder.delete_all
ProductPrice.delete_all
Product.delete_all
RoleAssignment.delete_all
Business.delete_all
User.delete_all

puts "Creando usuarios..."
owner = User.create!(
  name: "Santiago (Owner)",
  email: "owner@hermes.test",
  password: "password123",
  whatsapp_phone: "+573001000001",
  status: "active"
)

manager = User.create!(
  name: "Carolina (Manager)",
  email: "manager@hermes.test",
  password: "password123",
  whatsapp_phone: "+573001000002",
  status: "active"
)

puts "Creando negocio..."
tienda = Business.create!(
  name: "Tienda La Esquina",
  description: "Tienda de víveres, abarrotes y productos de primera necesidad",
  owner: owner,
  currency: "COP"
)

RoleAssignment.create!(
  user: manager,
  business: tienda,
  role: "manager",
  assigned_modules: "sales,purchases,inventory",
  status: "active",
  assigned_at: Time.current
)

puts "Creando productos..."
productos = [
  { name: "Arroz", description: "Arroz blanco corriente", unit_measure: "kg",  sale: 2_800,  purchase: 2_200, stock: 120, min: 30 },
  { name: "Aceite",  description: "Aceite vegetal", unit_measure: "lt",  sale: 7_500,  purchase: 6_000, stock: 40,  min: 10 },
  { name: "Azúcar",  description: "Azúcar refinada",  unit_measure: "kg",  sale: 3_200,  purchase: 2_600, stock: 80,  min: 20 },
  { name: "Sal",     description: "Sal de cocina",    unit_measure: "kg",  sale: 1_200,  purchase: 900,   stock: 50,  min: 15 },
  { name: "Panela",  description: "Panela redonda",   unit_measure: "und", sale: 3_500,  purchase: 2_800, stock: 30,  min: 10 },
  { name: "Café",    description: "Café molido 500g", unit_measure: "und", sale: 8_500,  purchase: 6_800, stock: 25,  min: 8  },
  { name: "Jabón",   description: "Jabón de baño",    unit_measure: "und", sale: 2_200,  purchase: 1_700, stock: 60,  min: 20 },
  { name: "Leche",   description: "Leche entera UHT", unit_measure: "lt",  sale: 3_800,  purchase: 3_000, stock: 45,  min: 12 }
]

productos.each do |attrs|
  product = Product.create!(
    business: tienda,
    name: attrs[:name],
    description: attrs[:description],
    unit_measure: attrs[:unit_measure],
    status: "active"
  )

  ProductPrice.create!(product: product, price_type: "sale",     unit_price: attrs[:sale],     start_at: Date.today)
  ProductPrice.create!(product: product, price_type: "purchase", unit_price: attrs[:purchase], start_at: Date.today)

  Inventory.create!(
    business: tienda,
    product: product,
    current_quantity: attrs[:stock],
    minimum_alert_quantity: attrs[:min],
    last_updated_at: Time.current
  )
end

puts "Creando órdenes de venta de ejemplo..."
arroz = Product.find_by!(name: "Arroz", business: tienda)
aceite = Product.find_by!(name: "Aceite", business: tienda)
azucar = Product.find_by!(name: "Azúcar", business: tienda)

venta1 = SalesOrder.create!(
  business: tienda,
  created_by: manager,
  reference_number: "OV-001",
  customer_name: "Don Julio",
  payment_condition: "cash",
  payment_status: "paid",
  total: 0,
  notes: "Cliente frecuente"
)
SalesOrderItem.create!(sales_order: venta1, product: arroz,  quantity: 5,  unit_price: 2_800, discount: 0)
SalesOrderItem.create!(sales_order: venta1, product: aceite, quantity: 2,  unit_price: 7_500, discount: 0)
venta1.recalculate_total!

venta2 = SalesOrder.create!(
  business: tienda,
  created_by: manager,
  reference_number: "OV-002",
  customer_name: "Doña María",
  payment_condition: "credit",
  payment_status: "pending",
  payment_due_at: 3.days.from_now,
  total: 0,
  notes: "Fiado, cobra el viernes"
)
SalesOrderItem.create!(sales_order: venta2, product: azucar, quantity: 3, unit_price: 3_200, discount: 0)
SalesOrderItem.create!(sales_order: venta2, product: arroz,  quantity: 10, unit_price: 2_800, discount: 5)
venta2.recalculate_total!

puts "Creando orden de compra de ejemplo..."
compra1 = PurchaseOrder.create!(
  business: tienda,
  created_by: owner,
  reference_number: "OC-001",
  supplier_name: "Distribuidora Juanito",
  status: "received",
  received_at: 2.days.ago,
  notes: "Pedido semanal"
)
PurchaseOrderItem.create!(purchase_order: compra1, product: arroz,  quantity: 50, unit_price: 2_200)
PurchaseOrderItem.create!(purchase_order: compra1, product: aceite, quantity: 20, unit_price: 6_000)
compra1.recalculate_total!

puts "\n✅ Seeds completados:"
puts "   Usuarios:  #{User.count}"
puts "   Negocios:  #{Business.count}"
puts "   Productos: #{Product.count}"
puts "   Inventario:#{Inventory.count} items"
puts "   Ventas:    #{SalesOrder.count}"
puts "   Compras:   #{PurchaseOrder.count}"
puts "\n📧 Login: owner@hermes.test / password123"
