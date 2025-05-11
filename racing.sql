CREATE TABLE IF NOT EXISTS `exter_racing` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `races` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

CREATE TABLE IF NOT EXISTS `exter_racing_alias` (
  `identifier` varchar(50) DEFAULT NULL,
  `alias` longtext DEFAULT NULL,
  `data` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;


CREATE TABLE IF NOT EXISTS `exter_racing_track` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `track_data` longtext DEFAULT NULL,
  `checkpoints` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;