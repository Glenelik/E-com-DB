-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it

-- Let's start by creating our Dimension tables for customers and Products we are selling

CREATE TABLE `customers` (
    `customer_id` INT AUTO_INCREMENT PRIMARY KEY,
    `customer_segment` ENUM('New', 'Occasional', 'Loyal') DEFAULT 'New',
    `customer_name` VARCHAR(60) UNIQUE NOT NULL,
    `email` VARCHAR(200),
    `phone` VARCHAR(17),
    `country` VARCHAR(20),
    `city` VARCHAR(40),
    `date_created` DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE  `products` (
    `product_id` INT AUTO_INCREMENT PRIMARY KEY,
    `product_name` VARCHAR(60),
    `price` DECIMAL(8,2),
    `category` ENUM('Tablets','Computers', 'Phones', 'Accessories') NOT NULL
);

-- lets also create a Log table that will store archived records about our deleted customers

CREATE TABLE `customers_deleted` (
    `customer_id` INT,
    `customer_name` VARCHAR(60),
    `email` VARCHAR(200),
    `phone` VARCHAR(17),
    `country` VARCHAR(20),
    `city` VARCHAR(40),
    `change_date` DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Now let's move on to creating our Fact tables related to purchase history and orders for our customers

CREATE TABLE `orders`(
    `order_id` INT AUTO_INCREMENT PRIMARY KEY,
    `customer_id` INT NOT NULL,
    `order_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `delivery_date` DATETIME,
    `order_status` ENUM('Pending', 'Shipped', 'Delivered'),
    FOREIGN KEY (`customer_id`) REFERENCES `customers`(`customer_id`)

);

CREATE TABLE `order_details` (
    `order_id` INT NOT NULL,
    `product_id` INT NOT NULL,
    `quantity` INT,
    `purchase_price` DECIMAL(8,2),
    FOREIGN KEY (`order_id`) REFERENCES `orders`(`order_id`),
    FOREIGN KEY (`product_id`) REFERENCES `products`(`product_id`)

);

CREATE TABLE `transactions` (
    `transaction_id` INT AUTO_INCREMENT PRIMARY KEY,
    `order_id` INT NOT NULL,
    `transaction_date` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `transaction_amount` DECIMAL(11,3),
    FOREIGN KEY (`order_id`) REFERENCES `orders`(`order_id`)
);

-- Now let's create indexes on the most commonly used columns across the tables we created

CREATE INDEX `index_order_details_product` ON `order_details`(`order_id`, `product_id`);
CREATE INDEX `index_customer_id` ON `orders`(`customer_id`);
CREATE INDEX `index_product_name` ON `products`(`product_name`);
CREATE INDEX `index_customer_name` ON `customers`(`customer_name`);

-- View to quickly access order history of a given customer if needed, by nesting it within a simple SELECT and WHERE clause

CREATE VIEW `customer_order_history` AS SELECT
    `customers`.`customer_id`,
    `customers`.`customer_name`,
    `orders`.`order_id`,
    `orders`.`order_date`,
    SUM(`order_details`.`quantity` * `order_details`.`purchase_price`) AS `total_order_value`
FROM `customers`
JOIN `orders`
    ON `orders`.`customer_id` = `customers`.`customer_id`
JOIN `order_details`
    ON `order_details`.`order_id` = `orders`.`order_id`
GROUP BY `customers`.`customer_id`, `orders`.`order_id`
ORDER BY `orders`.`order_date` DESC;

-- View to quickly address what are the top selling phones, similar could be created for all categories

CREATE VIEW `top_10_phones` AS SELECT
    `products`.`product_id`,
    `products`.`product_name`,
    SUM(`order_details`.`quantity`) AS `quantity_sold`
FROM `products`
JOIN `order_details`
    ON `order_details`.`product_id` = `products`.`product_id`
WHERE `products`.`category` = 'Phones'
GROUP BY `products`.`product_id`
ORDER BY `quantity_sold` DESC
LIMIT 10;

-- View to quickly address what loyal customers might be falling behing on orders in the current month

CREATE VIEW `loyal_customers_no_orders_this_month` AS
SELECT
    `customers`.`customer_id`,
    `customers`.`customer_name`,
    `customers`.`email`,
    `customers`.`phone`,
    `customers`.`country`,
    `customers`.`city`
FROM `customers`
LEFT JOIN `orders`
    ON `customers`.`customer_id` = `orders`.`customer_id`
    AND MONTH(`orders`.`order_date`) = MONTH(CURDATE())
    AND YEAR(`orders`.`order_date`) = YEAR(CURDATE())
WHERE `customers`.`customer_segment` = 'Loyal'
    AND `orders`.`order_id` IS NULL;

-- to slightly automate the processes in our DB, let's create a procidure that helps us to assign the customer segment.
-- Given that we are using ENUM for this column, let's define what each Segment would represent

DELIMITER //

CREATE PROCEDURE `update_customer_segments`()
BEGIN
UPDATE `customers`
JOIN
    (SELECT
        `orders`.`customer_id` AS `customer_id`,
        COUNT(`orders`.`order_id`) AS `order_count`,
        AVG(`order_details`.`quantity` * `order_details`.`purchase_price`) AS `avg_order_value`
    FROM `orders`
    JOIN `order_details` ON `orders`.`order_id` = `order_details`.`order_id`
    WHERE `orders`.`order_date` >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    GROUP BY `orders`.`customer_id`)

AS `Segmentation` ON `customers`.`customer_id` = `Segmentation`.`customer_id`

SET `customers`.`customer_segment` =
    IF(
    `Segmentation`.`order_count` >= 30 AND `Segmentation`.`avg_order_value` >= 5000,
    'Loyal',
    'Occasional')

WHERE `Segmentation`.`order_count` >= 5 AND `Segmentation`.`avg_order_value` >= 1000;

END //

-- Lets now create a trigger, to keep customer information in our DB, using a soft delition.
-- Just in case we would like to get back to them in the future

DELIMITER //

CREATE TRIGGER `before_customer_delete`
BEFORE DELETE ON `customers`
FOR EACH ROW
BEGIN
    INSERT INTO `customers_deleted` (
        `customer_id`,
        `customer_name`,
        `email`,
        `phone`,
        `country`,
        `city`,
        `change_date`
    )
    VALUES (
        OLD.`customer_id`,
        OLD.`customer_name`,
        OLD.`email`,
        OLD.`phone`,
        OLD.`country`,
        OLD.`city`,
        NOW()
    );
END //

DELIMITER ;







