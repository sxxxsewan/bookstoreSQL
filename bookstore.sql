-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1
-- Время создания: Дек 24 2025 г., 08:04
-- Версия сервера: 10.4.32-MariaDB
-- Версия PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `bookstore`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddOrder` (IN `cust_id` INT, IN `book_id` INT, IN `qty` INT)   BEGIN
    DECLARE book_price DECIMAL(10,2);
    DECLARE new_order_id INT;

    SELECT price
    INTO book_price
    FROM Books
    WHERE id = book_id;

    INSERT INTO Orders (customer_id, order_date, total_amount)
    VALUES (cust_id, CURDATE(), book_price * qty);

    SET new_order_id = LAST_INSERT_ID();

    INSERT INTO OrderItems (order_id, book_id, quantity, price)
    VALUES (new_order_id, book_id, qty, book_price);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateOrderStatus` (IN `ord_id` INT, IN `new_status` VARCHAR(20) CHARSET utf8mb4)   BEGIN
    UPDATE Orders
    SET status = new_status
    WHERE id = ord_id;
END$$

--
-- Функции
--
CREATE DEFINER=`root`@`localhost` FUNCTION `GetAverageRating` (`book_id` INT) RETURNS INT(11)  BEGIN
    DECLARE avg_rating DECIMAL(3,2);

    SELECT AVG(rating)
    INTO avg_rating
    FROM Reviews
    WHERE Reviews.book_id = book_id;

    RETURN IFNULL(avg_rating, 0);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `authors`
--

CREATE TABLE `authors` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `birth_year` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `authors`
--

INSERT INTO `authors` (`id`, `name`, `birth_year`) VALUES
(1, 'J.K. Rowling', 1965),
(2, 'George Orwell', 1903),
(3, 'J.R.R. Tolkien', 1892);

-- --------------------------------------------------------

--
-- Структура таблицы `books`
--

CREATE TABLE `books` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(200) DEFAULT NULL,
  `author_id` int(11) DEFAULT NULL,
  `publisher_id` int(11) DEFAULT NULL,
  `category_id` int(11) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `stock` int(11) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'in_stock' CHECK (`status` in ('in_stock','out_of_stock'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `books`
--

INSERT INTO `books` (`id`, `title`, `author_id`, `publisher_id`, `category_id`, `price`, `stock`, `status`) VALUES
(1, 'Harry Potter', 1, 1, 1, 19.99, 8, 'in_stock'),
(2, '1984', 2, 2, 2, 14.99, 5, 'in_stock'),
(3, 'The Hobbit', 3, 3, 3, 12.99, 8, 'in_stock');

--
-- Триггеры `books`
--
DELIMITER $$
CREATE TRIGGER `trg_update_book_status` BEFORE UPDATE ON `books` FOR EACH ROW BEGIN
    IF NEW.stock = 0 THEN
        SET NEW.status = 'out_of_stock';
    ELSE
        SET NEW.status = 'in_stock';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `categories`
--

INSERT INTO `categories` (`id`, `name`) VALUES
(1, 'Fantasy'),
(2, 'Dystopia'),
(3, 'Adventure');

-- --------------------------------------------------------

--
-- Структура таблицы `customers`
--

CREATE TABLE `customers` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `registration_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `customers`
--

INSERT INTO `customers` (`id`, `name`, `email`, `registration_date`) VALUES
(1, 'Alice Smith', 'alice@example.com', '2025-01-01'),
(2, 'Bob Johnson', 'bob@example.com', '2025-02-01'),
(3, 'Charlie Brown', 'charlie@example.com', '2025-03-01');

-- --------------------------------------------------------

--
-- Структура таблицы `orderitems`
--

CREATE TABLE `orderitems` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` int(11) DEFAULT NULL,
  `book_id` int(11) DEFAULT NULL,
  `quantity` int(11) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `orderitems`
--

INSERT INTO `orderitems` (`id`, `order_id`, `book_id`, `quantity`, `price`) VALUES
(1, 1, 1, 1, 19.99),
(2, 2, 2, 1, 14.99),
(3, 3, 3, 1, 12.99),
(4, 4, 1, 1, 19.99),
(5, 5, 1, 1, 19.99);

--
-- Триггеры `orderitems`
--
DELIMITER $$
CREATE TRIGGER `trg_check_stock_before_insert` BEFORE INSERT ON `orderitems` FOR EACH ROW BEGIN
    DECLARE current_stock INT;
    SELECT stock INTO current_stock 
    FROM Books 
    WHERE id = NEW.book_id;
    
    IF current_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Not enough stock';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_stock_after_insert` AFTER INSERT ON `orderitems` FOR EACH ROW BEGIN
    UPDATE Books 
    SET stock = stock - NEW.quantity 
    WHERE id = NEW.book_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `order_date` date DEFAULT NULL,
  `total_amount` decimal(10,2) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'pending' CHECK (`status` in ('pending','shipped','delivered'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `orders`
--

INSERT INTO `orders` (`id`, `customer_id`, `order_date`, `total_amount`, `status`) VALUES
(1, 1, '2025-12-01', 19.99, 'shipped'),
(2, 2, '2025-12-02', 14.99, 'pending'),
(3, 3, '2025-12-03', 12.99, 'pending'),
(4, 1, '2025-12-24', 19.99, 'pending'),
(5, 1, '2025-12-24', 19.99, 'pending');

-- --------------------------------------------------------

--
-- Структура таблицы `publishers`
--

CREATE TABLE `publishers` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `publishers`
--

INSERT INTO `publishers` (`id`, `name`, `location`) VALUES
(1, 'Bloomsbury', 'London'),
(2, 'Penguin', 'New York'),
(3, 'HarperCollins', 'London');

-- --------------------------------------------------------

--
-- Структура таблицы `reviews`
--

CREATE TABLE `reviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `book_id` int(11) DEFAULT NULL,
  `rating` int(11) DEFAULT NULL CHECK (`rating` between 1 and 5),
  `comment` text DEFAULT NULL,
  `review_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Дамп данных таблицы `reviews`
--

INSERT INTO `reviews` (`id`, `customer_id`, `book_id`, `rating`, `comment`, `review_date`) VALUES
(1, 1, 1, 5, 'Great book!', '2025-12-10'),
(2, 2, 2, 4, 'Thought-provoking', '2025-12-11'),
(3, 3, 3, 5, 'Epic adventure', '2025-12-12');

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `authors`
--
ALTER TABLE `authors`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `books`
--
ALTER TABLE `books`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `orderitems`
--
ALTER TABLE `orderitems`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `publishers`
--
ALTER TABLE `publishers`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `authors`
--
ALTER TABLE `authors`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `books`
--
ALTER TABLE `books`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `customers`
--
ALTER TABLE `customers`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `orderitems`
--
ALTER TABLE `orderitems`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT для таблицы `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT для таблицы `publishers`
--
ALTER TABLE `publishers`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
