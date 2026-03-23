// ============================================================
// Part 2: MongoDB Operations — E-Commerce Product Catalog
// Run in MongoDB Shell (mongosh) or MongoDB Compass shell
// Switch to working database first
// ============================================================

use("ecommerce_db");

// OP1: insertMany() — insert all 3 documents from sample_documents.json
db.products.insertMany([
  {
    product_id: "ELEC-001",
    name: "Sony WH-1000XM5 Wireless Headphones",
    category: "Electronics",
    brand: "Sony",
    price: 29990,
    currency: "INR",
    stock: 85,
    specs: {
      battery_life_hours: 30,
      connectivity: ["Bluetooth 5.2", "3.5mm Jack"],
      noise_cancellation: true,
      voltage: "5V DC",
      warranty_years: 1,
      color_options: ["Black", "Silver", "Midnight Blue"]
    },
    ratings: { average: 4.6, total_reviews: 1243 },
    tags: ["wireless", "noise-cancelling", "premium", "audio"],
    in_stock: true,
    created_at: new Date("2024-01-10")
  },
  {
    product_id: "CLTH-001",
    name: "Men's Slim Fit Cotton Kurta",
    category: "Clothing",
    brand: "FabIndia",
    price: 1299,
    currency: "INR",
    stock: 200,
    specs: {
      fabric: "100% Cotton",
      fit: "Slim Fit",
      sizes_available: ["S", "M", "L", "XL", "XXL"],
      color_options: ["White", "Light Blue", "Beige", "Olive"],
      care_instructions: ["Hand wash", "Do not bleach", "Iron on low heat"],
      occasion: ["Casual", "Festive"]
    },
    ratings: { average: 4.2, total_reviews: 587 },
    tags: ["ethnic", "cotton", "casual", "festive"],
    in_stock: true,
    created_at: new Date("2024-01-15")
  },
  {
    product_id: "GROC-001",
    name: "India Gate Classic Basmati Rice 5kg",
    category: "Groceries",
    brand: "India Gate",
    price: 649,
    currency: "INR",
    stock: 500,
    specs: {
      weight_kg: 5,
      expiry_date: new Date("2024-12-31"),
      manufactured_date: new Date("2024-03-01"),
      nutritional_info: {
        calories_per_100g: 350,
        carbohydrates_g: 78,
        protein_g: 7,
        fat_g: 0.5,
        fiber_g: 0.4
      },
      organic: false,
      allergens: [],
      storage: "Store in a cool, dry place",
      country_of_origin: "India",
      fssai_license: "10013022002733"
    },
    ratings: { average: 4.5, total_reviews: 3120 },
    tags: ["rice", "basmati", "staple", "gluten-free"],
    in_stock: true,
    created_at: new Date("2024-03-05")
  }
]);

// OP2: find() — retrieve all Electronics products with price > 20000
db.products.find(
  {
    category: "Electronics",
    price: { $gt: 20000 }
  },
  {
    name: 1,
    brand: 1,
    price: 1,
    "specs.warranty_years": 1,
    _id: 0
  }
);

// OP3: find() — retrieve all Groceries expiring before 2025-01-01
db.products.find(
  {
    category: "Groceries",
    "specs.expiry_date": { $lt: new Date("2025-01-01") }
  },
  {
    name: 1,
    "specs.expiry_date": 1,
    "specs.weight_kg": 1,
    price: 1,
    _id: 0
  }
);

// OP4: updateOne() — add a "discount_percent" field to a specific product (ELEC-001)
db.products.updateOne(
  { product_id: "ELEC-001" },
  {
    $set: {
      discount_percent: 10,
      discounted_price: 26991,
      discount_updated_at: new Date()
    }
  }
);

// OP5: createIndex() — create an index on the category field and explain why
//
// Reason: In an e-commerce product catalog, the most frequent query pattern is
// filtering by category (e.g., "show all Electronics", "find expiring Groceries").
// Without an index, MongoDB performs a full collection scan on every such query —
// O(n) cost that grows linearly as the catalog scales to millions of products.
// A B-tree index on 'category' reduces this to O(log n) lookups, dramatically
// improving query response times for category-filtered pages and reports.
// This is especially critical during peak traffic when category pages are
// hit thousands of times per second.
db.products.createIndex(
  { category: 1 },
  { name: "idx_category", background: true }
);

// Bonus: compound index on category + price for range queries like OP2
db.products.createIndex(
  { category: 1, price: -1 },
  { name: "idx_category_price_desc", background: true }
);
