-- Let's start with inserting some values to check if our queries are OK

INSERT INTO customers (customer_name, email, phone, country, city, date_created)
VALUES
('Customer 1', 'Email 1', 'Phone 1', 'Canada', 'Toronto', '2023-01-01 12:00:00'),
('Customer 2', 'Email 2', 'Phone 2', 'Canada', 'Toronto', '2023-01-02 12:00:00'),
('Customer 3', 'Email 3', 'Phone 3', 'Canada', 'Toronto', '2023-01-03 12:00:00'),
('Customer 4', 'Email 4', 'Phone 4', 'Canada', 'Toronto', '2023-01-04 12:00:00'),
('Customer 5', 'Email 5', 'Phone 5', 'Canada', 'Toronto', '2023-01-05 12:00:00');

INSERT INTO products (product_name, price, category)
VALUES
('Product 1', 100.00, 'Phones'),
('Product 2', 200.00, 'Computers'),
('Product 3', 150.00, 'Tablets'),
('Product 4', 50.00, 'Accessories'),
('Product 5', 75.00, 'Accessories'),
('Product 6', 100.00, 'Phones');


INSERT INTO orders (customer_id, order_date, delivery_date, order_status)
VALUES
(1, '2024-09-04 12:00:00', '2024-09-05 12:00:00', 'Delivered'),
(1, '2024-09-05 12:00:00', '2024-09-06 12:00:00', 'Shipped'),
(1, '2024-09-06 12:00:00', '2024-09-07 12:00:00', 'Pending'),
(1, '2024-09-07 12:00:00', '2024-09-08 12:00:00', 'Delivered'),
(1, '2024-09-08 12:00:00', '2024-09-09 12:00:00', 'Shipped'),
(2, '2024-09-08 12:00:00', '2024-09-09 12:00:00', 'Shipped');

INSERT INTO order_details (order_id, product_id, quantity, purchase_price)
VALUES
(1, 1, 5, 100.00),
(2, 2, 10, 200.00),
(3, 3, 30, 150.00),
(4, 4, 50, 50.00),
(5, 5, 2, 75.00),
(6, 6 ,1, 90.00);

INSERT INTO transactions (order_id, transaction_date, transaction_amount)
VALUES
(1, '2024-09-6 12:00:00', 500.00),
(2, '2024-09-7 12:00:00', 2000.00),
(3, '2024-09-8 12:00:00', 4500.00),
(4, '2024-09-9 12:00:00', 2500.00),
(5, '2024-09-10 12:00:00', 150.00),
(6, '2024-09-10 12:00:00', 90.00);

-- lets now check if our trigger works as intended

DELETE FROM `customers`
WHERE `customer_id` = 5;

-- customer id 5 should now be added to the customers deleted table

SELECT * FROM `customers_deleted`;

-- lets also check if our procedure updates our customers Segment accordingly

CALL `update_customer_segments`();

SELECT * FROM `customers`;

-- Now let's see some usecases of the queries we could run on our DB

-- Using our view for top 10 phones, lets see customers who have not purchased any phones from our top 10 list

SELECT `customers`.`customer_id`, `customers`.`customer_name`
FROM `customers`
JOIN `orders` ON `orders`.`customer_id` = `customers`.`customer_id`
JOIN `order_details` ON `order_details`.`order_id` = `orders`.`order_id`
JOIN `products` ON `products`.`product_id` = `order_details`.`product_id`
WHERE `products`.`category` = 'Phones'
AND `order_details`.`product_id` NOT IN (
    SELECT `top_10_phones`.`product_id`
    FROM `top_10_phones`
)
GROUP BY `customers`.`customer_id`;

-- Lets count number of customers we have under each segment

SELECT
    `customers`.`customer_segment`,
    COUNT(`customers`.`customer_segment`) AS `Customer_count_per_segment`
FROM `customers`
GROUP BY `customers`.`customer_segment`
ORDER BY `Customer_count_per_segment` DESC;

-- Lets take a look at the most popular product categories we have sold in 2024

SELECT
    `products`.`category`,
    SUM(`order_details`.`quantity` * `order_details`.`purchase_price`) AS `total_revenue`
FROM `products`
JOIN `order_details` ON `order_details`.`product_id` = `products`.`product_id`
JOIN `orders` ON `orders`.`order_id` = `order_details`.`order_id`
WHERE YEAR(`orders`.`order_date`) = 2024
GROUP BY `products`.`category`
ORDER BY `total_revenue` DESC;

-- What are the top 10 least sold products we have?

SELECT
    `products`.`product_id`,
    `products`.`product_name`,
    SUM(`order_details`.`quantity` * `order_details`.`purchase_price`) AS `total_revenue`
FROM `products`
JOIN `order_details` ON `order_details`.`product_id` = `products`.`product_id`
GROUP BY `products`.`product_id`, `products`.`product_name`
ORDER BY `total_revenue` ASC
LIMIT 10;

-- Adding a discount on all Accessories during the winter holidays

UPDATE `products`
SET `price` = `price` * 0.9
WHERE `category` = 'Accessories';









