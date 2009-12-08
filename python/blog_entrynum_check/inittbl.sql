DROP TABLE IF EXISTS `crawler_queue`;
CREATE TABLE `crawler_queue` (
  `id` int(11) DEFAULT NULL,
  `fail_cnt` int(11) DEFAULT '0'
) ENGINE=QUEUE DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `diaries`;
CREATE TABLE `diaries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` text,
  `title` text,
  `entry_num` int(11) DEFAULT NULL,
  `bookmarks` int(11) DEFAULT NULL,
  `subscribers` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=95359 DEFAULT CHARSET=latin1;

DELIMITER ;;
CREATE TRIGGER update_crawler_queue AFTER INSERT ON diaries 
FOR EACH ROW BEGIN 
INSERT INTO crawler_queue SET id=NEW.id; 
END;;
DELIMITER ;
