USE flipkart_db;

-- MySQL Workbench blocks UPDATE/DELETE statements that do not filter on a key
-- column (error 1175). Turning safe-update mode off for this session lets the
-- name-based UPDATE and DELETE statements below run.
SET SQL_SAFE_UPDATES = 0;

-- ============ 1. CREATE TABLES ============

CREATE TABLE inventory (
    inventory_id   INT AUTO_INCREMENT PRIMARY KEY,
    product_id     INT NOT NULL UNIQUE,              
    seller_id      INT NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    stock_status   VARCHAR(20) DEFAULT 'In-Stock',
    CONSTRAINT chk_inventory_stock CHECK (stock_quantity >= 0),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
        REFERENCES product(product_id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_seller  FOREIGN KEY (seller_id)
        REFERENCES seller(seller_id)
);

-- ============ 2. CONSTRAINTS & RELATIONSHIPS ============

ALTER TABLE seller
    ADD CONSTRAINT chk_seller_phone CHECK (phone REGEXP '^[0-9]{10}$');  

DESCRIBE seller;
DESCRIBE inventory;

-- ============ 3. SELLER & PRODUCT OPERATIONS ============

-- 3.1 Add seller details (three new sellers)
INSERT INTO seller (seller_name, email, phone, address) VALUES
('Urban Style Traders', 'urbanstyle@mail.com',  '9000000011', '22 Residency Road, Bengaluru, Karnataka'),
('Fresh Basket Foods',  'freshbasket@mail.com', '9000000012', '6 Race Course Road, Coimbatore, Tamil Nadu'),
('Craft Corner',        'craftcorner@mail.com', '9000000013', '31 Bazaar Street, Jaipur, Rajasthan');

-- 3.2 Add new products with no seller yet, then assign them to sellers
INSERT INTO product (product_name, category_id, price, stock_quantity, seller_id) VALUES
('Denim Jacket',       2, 1799.00,  8, NULL),
('Leather Wallet',     2,  599.00,  0, NULL),
('Almonds 500g',       8,  549.00,  5, NULL),
('Green Tea 100 Bags', 8,  299.00,  0, NULL),
('Cotton Bedsheet',    3,  899.00, 60, NULL),
('Cricket Ball Pack',  5,  349.00,  0, NULL);

-- Products that still have no seller
SELECT product_id, product_name FROM product WHERE seller_id IS NULL;

-- Assign products to sellers (the seller id is looked up by name)
UPDATE product
SET seller_id = (SELECT seller_id FROM seller WHERE seller_name = 'Urban Style Traders')
WHERE product_name IN ('Denim Jacket', 'Leather Wallet');

UPDATE product
SET seller_id = (SELECT seller_id FROM seller WHERE seller_name = 'Fresh Basket Foods')
WHERE product_name IN ('Almonds 500g', 'Green Tea 100 Bags');

UPDATE product
SET seller_id = (SELECT seller_id FROM seller WHERE seller_name = 'HomeEssentials')
WHERE product_name = 'Cotton Bedsheet';

UPDATE product
SET seller_id = (SELECT seller_id FROM seller WHERE seller_name = 'SportsZone')
WHERE product_name = 'Cricket Ball Pack';

-- 3.3 Display products supplied by each seller
SELECT s.seller_name, p.product_id, p.product_name, p.price
FROM seller s
JOIN product p ON s.seller_id = p.seller_id
ORDER BY s.seller_name, p.product_name;

-- 3.4 Count products supplied by each seller
SELECT s.seller_id, s.seller_name, COUNT(p.product_id) AS total_products
FROM seller s
LEFT JOIN product p ON s.seller_id = p.seller_id
GROUP BY s.seller_id, s.seller_name
ORDER BY total_products DESC, s.seller_name;

-- 3.5 Update seller details
UPDATE seller SET address = '18 Avinashi Road, Coimbatore, Tamil Nadu' WHERE seller_name = 'KitchenKart';
UPDATE seller SET phone = '9100000011', email = 'urbanstyle.traders@mail.com'
WHERE seller_name = 'Urban Style Traders';
SELECT seller_id, seller_name, email, phone, address FROM seller
WHERE seller_name IN ('KitchenKart', 'Urban Style Traders');

-- ============ 4. INVENTORY OPERATIONS ============

-- 4.0 Create one inventory record for every product (INSERT ... SELECT).
INSERT INTO inventory (product_id, seller_id, stock_quantity)
SELECT product_id, seller_id, stock_quantity
FROM product
WHERE seller_id IS NOT NULL;

SELECT * FROM inventory;

-- 4.1 Display available products (stock greater than 0)
SELECT p.product_id, p.product_name, i.stock_quantity, i.stock_status
FROM inventory i
JOIN product p ON i.product_id = p.product_id
WHERE i.stock_quantity > 0
ORDER BY p.product_name;

-- 4.2 Find out-of-stock products
SELECT p.product_id, p.product_name, s.seller_name, i.stock_status
FROM inventory i
JOIN product p ON i.product_id = p.product_id
JOIN seller  s ON i.seller_id  = s.seller_id
WHERE i.stock_quantity = 0;

-- 4.3 Find products with stock less than 10 (includes out-of-stock products)
SELECT p.product_id, p.product_name, i.stock_quantity, i.stock_status
FROM inventory i
JOIN product p ON i.product_id = p.product_id
WHERE i.stock_quantity < 10
ORDER BY i.stock_quantity, p.product_name;

-- 4.4 Update stock quantity
UPDATE inventory i
JOIN product p ON i.product_id = p.product_id
SET i.stock_quantity = 50,
    p.stock_quantity = 50
WHERE p.product_name = 'Leather Wallet';

-- Sale: 3 units of Almonds 500g are sold (5 -> 2)
UPDATE inventory i
JOIN product p ON i.product_id = p.product_id
SET i.stock_quantity = i.stock_quantity - 3,
    p.stock_quantity = p.stock_quantity - 3
WHERE p.product_name = 'Almonds 500g';

SELECT p.product_name, i.stock_quantity, i.stock_status, i.last_updated
FROM inventory i
JOIN product p ON i.product_id = p.product_id
WHERE p.product_name IN ('Leather Wallet', 'Almonds 500g');

-- 4.5 Delete discontinued inventory
DELETE FROM inventory
WHERE product_id = (SELECT product_id FROM product WHERE product_name = 'Green Tea 100 Bags');

-- ============ 5. INVENTORY REPORTS ============

-- 5.1 Seller-wise product report
SELECT s.seller_name, p.product_name, c.category_name, p.price,
       i.stock_quantity, i.stock_status
FROM inventory i
JOIN product  p ON i.product_id  = p.product_id
JOIN seller   s ON i.seller_id   = s.seller_id
JOIN category c ON p.category_id = c.category_id
ORDER BY s.seller_name, p.product_name;

-- 5.1b Seller-wise summary: products listed and total stock for every seller
SELECT s.seller_name,
       COUNT(i.inventory_id)         AS products_listed,
       COALESCE(SUM(i.stock_quantity), 0) AS total_stock
FROM seller s
LEFT JOIN inventory i ON s.seller_id = i.seller_id
GROUP BY s.seller_id, s.seller_name
ORDER BY total_stock DESC, s.seller_name;

-- 5.2 Stock availability report
-- Summary by status
SELECT stock_status,
       COUNT(*)            AS total_products,
       SUM(stock_quantity) AS total_units
FROM inventory
GROUP BY stock_status
ORDER BY FIELD(stock_status, 'In Stock', 'Low Stock', 'Out of Stock');

-- Product-level list, lowest stock first
SELECT p.product_name, s.seller_name, i.stock_quantity, i.stock_status
FROM inventory i
JOIN product p ON i.product_id = p.product_id
JOIN seller  s ON i.seller_id  = s.seller_id
ORDER BY i.stock_quantity, p.product_name;

-- 5.3 Total available products (stock greater than 0)
SELECT COUNT(*) AS total_available_products
FROM inventory
WHERE stock_quantity > 0;

-- 5.4 Out-of-stock products
SELECT p.product_id, p.product_name, s.seller_name
FROM inventory i
JOIN product p ON i.product_id = p.product_id
JOIN seller  s ON i.seller_id  = s.seller_id
WHERE i.stock_status = 'Out of Stock';

-- 5.5 Highest stocked product
SELECT p.product_id, p.product_name, s.seller_name, i.stock_quantity
FROM inventory i
JOIN product p ON i.product_id = p.product_id
JOIN seller  s ON i.seller_id  = s.seller_id
WHERE i.stock_quantity = (SELECT MAX(stock_quantity) FROM inventory);

-- 5.6 Average inventory quantity
SELECT ROUND(AVG(stock_quantity), 2) AS average_inventory_quantity FROM inventory;

-- 5.6b Average inventory quantity per seller
SELECT s.seller_name, ROUND(AVG(i.stock_quantity), 2) AS average_stock
FROM seller s
JOIN inventory i ON s.seller_id = i.seller_id
GROUP BY s.seller_id, s.seller_name
ORDER BY average_stock DESC;