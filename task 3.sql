CREATE DATABASE SellerInventoryDB;

USE SellerInventoryDB;

CREATE TABLE Product (
    Product_ID INT PRIMARY KEY AUTO_INCREMENT,
    Product_Name VARCHAR(100) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    CHECK (Price > 0)
);
INSERT INTO Product (Product_Name, Price)
VALUES
('Laptop', 50000),
('Mouse', 800),
('Keyboard', 1500),
('Monitor', 12000),
('Printer', 15000),
('Headphones', 2000),
('Webcam', 3000),
('Speaker', 2500);

SELECT * FROM Product;

CREATE TABLE Seller (
    Seller_ID INT PRIMARY KEY AUTO_INCREMENT,
    Seller_Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(15) NOT NULL UNIQUE,
    Address VARCHAR(255) NOT NULL
);

CREATE TABLE Inventory (
    Inventory_ID INT PRIMARY KEY AUTO_INCREMENT,
    Product_ID INT NOT NULL,
    Seller_ID INT NOT NULL,
    Stock_Quantity INT NOT NULL,
    Stock_Status VARCHAR(20) NOT NULL,
    Last_Updated DATE NOT NULL,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (Product_ID)
        REFERENCES Product(Product_ID),

    CONSTRAINT fk_inventory_seller
        FOREIGN KEY (Seller_ID)
        REFERENCES Seller(Seller_ID),

    CONSTRAINT check_stock_quantity
        CHECK (Stock_Quantity >= 0),

    CONSTRAINT check_stock_status
        CHECK (Stock_Status IN ('Available', 'Out of Stock'))
);

INSERT INTO Seller (Seller_Name, Email, Phone, Address)
VALUES
('ABC Traders', 'abc@gmail.com', '9876543210', 'Chennai'),
('Tech World', 'techworld@gmail.com', '9876543211', 'Coimbatore'),
('Smart Mart', 'smartmart@gmail.com', '9876543212', 'Madurai'),
('Digital Hub', 'digitalhub@gmail.com', '9876543213', 'Trichy'),
('Global Stores', 'globalstores@gmail.com', '9876543214', 'Salem');
SELECT * FROM Seller;

INSERT INTO Inventory
(Product_ID, Seller_ID, Stock_Quantity, Stock_Status, Last_Updated)
VALUES
(1, 1, 25, 'Available', '2026-09-28'),
(2, 1, 8, 'Available', '2026-09-28'),
(3, 2, 15, 'Available', '2026-09-28'),
(4, 2, 0, 'Out of Stock', '2026-09-28'),
(5, 3, 30, 'Available', '2026-09-28'),
(6, 3, 5, 'Available', '2026-09-28'),
(7, 4, 12, 'Available', '2026-09-28'),
(8, 5, 0, 'Out of Stock', '2026-09-28');
SELECT 	* FROM Inventory;

SELECT 
    s.Seller_Name,
    p.Product_Name,
    i.Stock_Quantity
FROM Seller s
JOIN Inventory i
    ON s.Seller_ID = i.Seller_ID
JOIN Product p
    ON i.Product_ID = p.Product_ID;
    
SELECT 
    s.Seller_Name,
    COUNT(i.Product_ID) AS Product_Count
FROM Seller s
LEFT JOIN Inventory i
    ON s.Seller_ID = i.Seller_ID
GROUP BY s.Seller_ID, s.Seller_Name;

UPDATE Seller
SET Address = 'Bangalore'
WHERE Seller_ID = 1;
SELECT * FROM Seller
WHERE Seller_ID = 1;

SELECT 
    p.Product_ID,
    p.Product_Name,
    i.Stock_Quantity
FROM Product p
JOIN Inventory i
    ON p.Product_ID = i.Product_ID
WHERE i.Stock_Quantity > 0;

SELECT 
    p.Product_ID,
    p.Product_Name
FROM Product p
JOIN Inventory i
    ON p.Product_ID = i.Product_ID
WHERE i.Stock_Quantity = 0;

SELECT 
    p.Product_ID,
    p.Product_Name,
    i.Stock_Quantity
FROM Product p
JOIN Inventory i
    ON p.Product_ID = i.Product_ID
WHERE i.Stock_Quantity < 10;

UPDATE Inventory
SET Stock_Quantity = 20,
    Stock_Status = 'Available',
    Last_Updated = CURDATE()
WHERE Product_ID = 2;

DELETE FROM Inventory
WHERE Stock_Quantity = 0;

SELECT 
    s.Seller_Name,
    p.Product_Name,
    i.Stock_Quantity,
    i.Stock_Status
FROM Seller s
JOIN Inventory i
    ON s.Seller_ID = i.Seller_ID
JOIN Product p
    ON i.Product_ID = p.Product_ID
ORDER BY s.Seller_Name;

SELECT 
    p.Product_Name,
    i.Stock_Quantity,
    i.Stock_Status,
    i.Last_Updated
FROM Product p
JOIN Inventory i
    ON p.Product_ID = i.Product_ID;
    
SELECT SUM(Stock_Quantity) AS Total_Available_Products
FROM Inventory
WHERE Stock_Quantity > 0;

SELECT COUNT(DISTINCT Product_ID) AS Out_of_Stock_Products
FROM Inventory
WHERE Stock_Quantity = 0;

SELECT 
    p.Product_Name,
    i.Stock_Quantity
FROM Product p
JOIN Inventory i
    ON p.Product_ID = i.Product_ID
WHERE i.Stock_Quantity = (
    SELECT MAX(Stock_Quantity)
    FROM Inventory
);

SELECT 
    AVG(Stock_Quantity) AS Average_Inventory_Quantity
FROM Inventory;