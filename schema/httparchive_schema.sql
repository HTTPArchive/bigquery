-- MySQL dump 10.13  Distrib 5.5.37, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: httparchive
-- ------------------------------------------------------
-- Server version	5.5.37-0ubuntu0.12.04.1-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `stats`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stats` (
  `label` varchar(32) NOT NULL,
  `crawlid` int(10) unsigned NOT NULL,
  `slice` varchar(32) NOT NULL,
  `device` varchar(32) NOT NULL,
  `version` int(6) unsigned NOT NULL,
  `numurls` int(10) unsigned DEFAULT NULL,
  `PageSpeed` float unsigned DEFAULT NULL,
  `SpeedIndex` mediumint(8) unsigned DEFAULT NULL,
  `TTFB` int(10) unsigned DEFAULT NULL,
  `renderStart` int(10) unsigned DEFAULT NULL,
  `onLoad` int(10) unsigned DEFAULT NULL,
  `visualComplete` int(10) unsigned DEFAULT NULL,
  `fullyLoaded` int(10) unsigned DEFAULT NULL,
  `numDomains` float unsigned DEFAULT NULL,
  `maxDomainReqs` smallint(5) unsigned NOT NULL,
  `numDomElements` mediumint(8) unsigned NOT NULL,
  `reqTotal` float unsigned DEFAULT NULL,
  `reqHtml` float unsigned DEFAULT NULL,
  `reqJS` float unsigned DEFAULT NULL,
  `reqCSS` float unsigned DEFAULT NULL,
  `reqImg` float unsigned DEFAULT NULL,
  `reqGif` float unsigned DEFAULT NULL,
  `reqJpg` float unsigned DEFAULT NULL,
  `reqPng` float unsigned DEFAULT NULL,
  `reqFlash` float unsigned DEFAULT NULL,
  `reqFont` float unsigned DEFAULT NULL,
  `reqJson` float unsigned DEFAULT NULL,
  `reqOther` float unsigned DEFAULT NULL,
  `bytesTotal` int(10) unsigned DEFAULT NULL,
  `bytesHtml` int(10) unsigned DEFAULT NULL,
  `bytesJS` int(10) unsigned DEFAULT NULL,
  `bytesCSS` int(10) unsigned DEFAULT NULL,
  `bytesImg` int(10) unsigned DEFAULT NULL,
  `bytesGif` int(10) unsigned DEFAULT NULL,
  `bytesJpg` int(10) unsigned DEFAULT NULL,
  `bytesPng` int(10) unsigned DEFAULT NULL,
  `bytesFlash` int(10) unsigned DEFAULT NULL,
  `bytesFont` int(10) unsigned DEFAULT NULL,
  `bytesJson` int(10) unsigned DEFAULT NULL,
  `bytesOther` int(10) unsigned DEFAULT NULL,
  `bytesHtmlDoc` mediumint(8) unsigned DEFAULT NULL,
  `gzipTotal` int(10) unsigned NOT NULL,
  `gzipSavings` int(10) unsigned NOT NULL,
  `perRedirects` int(4) unsigned DEFAULT NULL,
  `perErrors` int(4) unsigned DEFAULT NULL,
  `perFlash` int(4) unsigned DEFAULT NULL,
  `perFonts` int(4) unsigned DEFAULT NULL,
  `perGlibs` int(4) unsigned DEFAULT NULL,
  `perCdn` int(4) unsigned DEFAULT NULL,
  `perHttps` int(4) unsigned DEFAULT NULL,
  `perCompressed` int(4) unsigned DEFAULT NULL,
  `maxageNull` int(4) unsigned DEFAULT NULL,
  `maxage0` int(4) unsigned DEFAULT NULL,
  `maxage1` int(4) unsigned DEFAULT NULL,
  `maxage30` int(4) unsigned DEFAULT NULL,
  `maxage365` int(4) unsigned DEFAULT NULL,
  `maxageMore` int(4) unsigned DEFAULT NULL,
  `onLoadccf1` varchar(32) DEFAULT NULL,
  `onLoadccv1` float unsigned DEFAULT NULL,
  `onLoadccf2` varchar(32) DEFAULT NULL,
  `onLoadccv2` float unsigned DEFAULT NULL,
  `onLoadccf3` varchar(32) DEFAULT NULL,
  `onLoadccv3` float unsigned DEFAULT NULL,
  `onLoadccf4` varchar(32) DEFAULT NULL,
  `onLoadccv4` float unsigned DEFAULT NULL,
  `onLoadccf5` varchar(32) DEFAULT NULL,
  `onLoadccv5` float unsigned DEFAULT NULL,
  `renderStartccf1` varchar(32) DEFAULT NULL,
  `renderStartccv1` float unsigned DEFAULT NULL,
  `renderStartccf2` varchar(32) DEFAULT NULL,
  `renderStartccv2` float unsigned DEFAULT NULL,
  `renderStartccf3` varchar(32) DEFAULT NULL,
  `renderStartccv3` float unsigned DEFAULT NULL,
  `renderStartccf4` varchar(32) DEFAULT NULL,
  `renderStartccv4` float unsigned DEFAULT NULL,
  `renderStartccf5` varchar(32) DEFAULT NULL,
  `renderStartccv5` float unsigned DEFAULT NULL,
  `_connections` int(4) unsigned NOT NULL,
  PRIMARY KEY (`label`,`slice`,`device`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `requests`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `requests` (
  `requestid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pageid` int(10) unsigned NOT NULL,
  `startedDateTime` int(10) unsigned DEFAULT NULL,
  `time` int(10) unsigned DEFAULT NULL,
  `method` varchar(32) DEFAULT NULL,
  `url` text,
  `urlShort` varchar(255) DEFAULT NULL,
  `redirectUrl` text,
  `firstReq` tinyint(1) NOT NULL,
  `firstHtml` tinyint(1) NOT NULL,
  `reqHttpVersion` varchar(32) DEFAULT NULL,
  `reqHeadersSize` int(10) unsigned DEFAULT NULL,
  `reqBodySize` int(10) unsigned DEFAULT NULL,
  `reqCookieLen` int(10) unsigned NOT NULL,
  `reqOtherHeaders` text,
  `status` int(10) unsigned DEFAULT NULL,
  `respHttpVersion` varchar(32) DEFAULT NULL,
  `respHeadersSize` int(10) unsigned DEFAULT NULL,
  `respBodySize` int(10) unsigned DEFAULT NULL,
  `respSize` int(10) unsigned DEFAULT NULL,
  `respCookieLen` int(10) unsigned NOT NULL,
  `expAge` int(10) unsigned NOT NULL,
  `mimeType` varchar(255) DEFAULT NULL,
  `respOtherHeaders` text,
  `req_accept` varchar(255) DEFAULT NULL,
  `req_accept_charset` varchar(255) DEFAULT NULL,
  `req_accept_encoding` varchar(255) DEFAULT NULL,
  `req_accept_language` varchar(255) DEFAULT NULL,
  `req_connection` varchar(255) DEFAULT NULL,
  `req_host` varchar(255) DEFAULT NULL,
  `req_if_modified_since` varchar(255) DEFAULT NULL,
  `req_if_none_match` varchar(255) DEFAULT NULL,
  `req_referer` varchar(255) DEFAULT NULL,
  `req_user_agent` varchar(255) DEFAULT NULL,
  `resp_accept_ranges` varchar(255) DEFAULT NULL,
  `resp_age` varchar(255) DEFAULT NULL,
  `resp_cache_control` varchar(255) DEFAULT NULL,
  `resp_connection` varchar(255) DEFAULT NULL,
  `resp_content_encoding` varchar(255) DEFAULT NULL,
  `resp_content_language` varchar(255) DEFAULT NULL,
  `resp_content_length` varchar(255) DEFAULT NULL,
  `resp_content_location` varchar(255) DEFAULT NULL,
  `resp_content_type` varchar(255) DEFAULT NULL,
  `resp_date` varchar(255) DEFAULT NULL,
  `resp_etag` varchar(255) DEFAULT NULL,
  `resp_expires` varchar(255) DEFAULT NULL,
  `resp_keep_alive` varchar(255) DEFAULT NULL,
  `resp_last_modified` varchar(255) DEFAULT NULL,
  `resp_location` varchar(255) DEFAULT NULL,
  `resp_pragma` varchar(255) DEFAULT NULL,
  `resp_server` varchar(255) DEFAULT NULL,
  `resp_transfer_encoding` varchar(255) DEFAULT NULL,
  `resp_vary` varchar(255) DEFAULT NULL,
  `resp_via` varchar(255) DEFAULT NULL,
  `resp_x_powered_by` varchar(255) DEFAULT NULL,
  `_cdn_provider` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`requestid`),
  UNIQUE KEY `startedDateTime` (`startedDateTime`,`pageid`,`urlShort`),
  KEY `pageid` (`pageid`)
) ENGINE=MyISAM AUTO_INCREMENT=1380813622 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pages`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pages` (
  `pageid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `createDate` int(10) unsigned NOT NULL,
  `archive` varchar(16) NOT NULL,
  `label` varchar(32) NOT NULL,
  `crawlid` int(10) unsigned NOT NULL,
  `wptid` varchar(64) NOT NULL,
  `wptrun` int(2) unsigned NOT NULL,
  `url` text,
  `urlShort` varchar(255) DEFAULT NULL,
  `urlhash` int(8) unsigned DEFAULT NULL,
  `cdn` varchar(64) DEFAULT NULL,
  `startedDateTime` int(10) unsigned DEFAULT NULL,
  `TTFB` smallint(5) unsigned DEFAULT NULL,
  `renderStart` int(10) unsigned DEFAULT NULL,
  `onContentLoaded` int(10) unsigned DEFAULT NULL,
  `onLoad` int(10) unsigned DEFAULT NULL,
  `fullyLoaded` int(10) unsigned DEFAULT NULL,
  `visualComplete` int(10) unsigned DEFAULT NULL,
  `PageSpeed` int(4) unsigned DEFAULT NULL,
  `SpeedIndex` mediumint(8) unsigned DEFAULT NULL,
  `rank` int(10) unsigned DEFAULT NULL,
  `reqTotal` int(4) unsigned NOT NULL,
  `reqHtml` int(4) unsigned NOT NULL,
  `reqJS` int(4) unsigned NOT NULL,
  `reqCSS` int(4) unsigned NOT NULL,
  `reqImg` int(4) unsigned NOT NULL,
  `reqGif` smallint(5) unsigned NOT NULL,
  `reqJpg` smallint(5) unsigned NOT NULL,
  `reqPng` smallint(5) unsigned NOT NULL,
  `reqFont` smallint(5) unsigned NOT NULL,
  `reqFlash` int(4) unsigned NOT NULL,
  `reqJson` int(4) unsigned NOT NULL,
  `reqOther` int(4) unsigned NOT NULL,
  `bytesTotal` int(10) unsigned NOT NULL,
  `bytesHtml` int(10) unsigned NOT NULL,
  `bytesJS` int(10) unsigned NOT NULL,
  `bytesCSS` int(10) unsigned NOT NULL,
  `bytesImg` int(10) unsigned NOT NULL,
  `bytesGif` int(10) unsigned NOT NULL,
  `bytesJpg` int(10) unsigned NOT NULL,
  `bytesPng` int(10) unsigned NOT NULL,
  `bytesFont` int(10) unsigned NOT NULL,
  `bytesFlash` int(10) unsigned NOT NULL,
  `bytesJson` int(10) unsigned NOT NULL,
  `bytesOther` int(10) unsigned NOT NULL,
  `bytesHtmlDoc` mediumint(8) unsigned NOT NULL,
  `numDomains` int(4) unsigned NOT NULL,
  `maxDomainReqs` smallint(5) unsigned NOT NULL,
  `numRedirects` smallint(5) unsigned NOT NULL,
  `numErrors` smallint(5) unsigned NOT NULL,
  `numGlibs` smallint(5) unsigned NOT NULL,
  `numHttps` smallint(5) unsigned NOT NULL,
  `numCompressed` smallint(5) unsigned NOT NULL,
  `numDomElements` mediumint(8) unsigned NOT NULL,
  `maxageNull` smallint(5) unsigned NOT NULL,
  `maxage0` smallint(5) unsigned NOT NULL,
  `maxage1` smallint(5) unsigned NOT NULL,
  `maxage30` smallint(5) unsigned NOT NULL,
  `maxage365` smallint(5) unsigned NOT NULL,
  `maxageMore` smallint(5) unsigned NOT NULL,
  `gzipTotal` int(10) unsigned NOT NULL,
  `gzipSavings` int(10) unsigned NOT NULL,
  `_connections` int(4) unsigned NOT NULL,
  `_adult_site` tinyint(1) NOT NULL,
  PRIMARY KEY (`pageid`),
  UNIQUE KEY `label` (`label`,`urlShort`),
  KEY `urlhash` (`urlhash`)
) ENGINE=MyISAM AUTO_INCREMENT=16399092 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `requestsmobile`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `requestsmobile` (
  `requestid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pageid` int(10) unsigned NOT NULL,
  `startedDateTime` int(10) unsigned DEFAULT NULL,
  `time` int(10) unsigned DEFAULT NULL,
  `method` varchar(32) DEFAULT NULL,
  `url` text,
  `urlShort` varchar(255) DEFAULT NULL,
  `redirectUrl` text,
  `firstReq` tinyint(1) NOT NULL,
  `firstHtml` tinyint(1) NOT NULL,
  `reqHttpVersion` varchar(32) DEFAULT NULL,
  `reqHeadersSize` int(10) unsigned DEFAULT NULL,
  `reqBodySize` int(10) unsigned DEFAULT NULL,
  `reqCookieLen` int(10) unsigned NOT NULL,
  `reqOtherHeaders` text,
  `status` int(10) unsigned DEFAULT NULL,
  `respHttpVersion` varchar(32) DEFAULT NULL,
  `respHeadersSize` int(10) unsigned DEFAULT NULL,
  `respBodySize` int(10) unsigned DEFAULT NULL,
  `respSize` int(10) unsigned DEFAULT NULL,
  `respCookieLen` int(10) unsigned NOT NULL,
  `expAge` int(10) unsigned NOT NULL,
  `mimeType` varchar(255) DEFAULT NULL,
  `respOtherHeaders` text,
  `req_accept` varchar(255) DEFAULT NULL,
  `req_accept_charset` varchar(255) DEFAULT NULL,
  `req_accept_encoding` varchar(255) DEFAULT NULL,
  `req_accept_language` varchar(255) DEFAULT NULL,
  `req_connection` varchar(255) DEFAULT NULL,
  `req_host` varchar(255) DEFAULT NULL,
  `req_if_modified_since` varchar(255) DEFAULT NULL,
  `req_if_none_match` varchar(255) DEFAULT NULL,
  `req_referer` varchar(255) DEFAULT NULL,
  `req_user_agent` varchar(255) DEFAULT NULL,
  `resp_accept_ranges` varchar(255) DEFAULT NULL,
  `resp_age` varchar(255) DEFAULT NULL,
  `resp_cache_control` varchar(255) DEFAULT NULL,
  `resp_connection` varchar(255) DEFAULT NULL,
  `resp_content_encoding` varchar(255) DEFAULT NULL,
  `resp_content_language` varchar(255) DEFAULT NULL,
  `resp_content_length` varchar(255) DEFAULT NULL,
  `resp_content_location` varchar(255) DEFAULT NULL,
  `resp_content_type` varchar(255) DEFAULT NULL,
  `resp_date` varchar(255) DEFAULT NULL,
  `resp_etag` varchar(255) DEFAULT NULL,
  `resp_expires` varchar(255) DEFAULT NULL,
  `resp_keep_alive` varchar(255) DEFAULT NULL,
  `resp_last_modified` varchar(255) DEFAULT NULL,
  `resp_location` varchar(255) DEFAULT NULL,
  `resp_pragma` varchar(255) DEFAULT NULL,
  `resp_server` varchar(255) DEFAULT NULL,
  `resp_transfer_encoding` varchar(255) DEFAULT NULL,
  `resp_vary` varchar(255) DEFAULT NULL,
  `resp_via` varchar(255) DEFAULT NULL,
  `resp_x_powered_by` varchar(255) DEFAULT NULL,
  `_cdn_provider` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`requestid`),
  UNIQUE KEY `startedDateTime` (`startedDateTime`,`pageid`,`urlShort`),
  KEY `pageid` (`pageid`)
) ENGINE=MyISAM AUTO_INCREMENT=15941581 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `pagesmobile`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pagesmobile` (
  `pageid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `createDate` int(10) unsigned NOT NULL,
  `archive` varchar(16) NOT NULL,
  `label` varchar(32) NOT NULL,
  `crawlid` int(10) unsigned NOT NULL,
  `wptid` varchar(64) NOT NULL,
  `wptrun` int(2) unsigned NOT NULL,
  `url` text,
  `urlShort` varchar(255) DEFAULT NULL,
  `urlhash` int(8) unsigned DEFAULT NULL,
  `cdn` varchar(64) DEFAULT NULL,
  `startedDateTime` int(10) unsigned DEFAULT NULL,
  `TTFB` smallint(5) unsigned DEFAULT NULL,
  `renderStart` int(10) unsigned DEFAULT NULL,
  `onContentLoaded` int(10) unsigned DEFAULT NULL,
  `onLoad` int(10) unsigned DEFAULT NULL,
  `fullyLoaded` int(10) unsigned DEFAULT NULL,
  `visualComplete` int(10) unsigned DEFAULT NULL,
  `PageSpeed` int(4) unsigned DEFAULT NULL,
  `SpeedIndex` mediumint(8) unsigned DEFAULT NULL,
  `rank` int(10) unsigned DEFAULT NULL,
  `reqTotal` int(4) unsigned NOT NULL,
  `reqHtml` int(4) unsigned NOT NULL,
  `reqJS` int(4) unsigned NOT NULL,
  `reqCSS` int(4) unsigned NOT NULL,
  `reqImg` int(4) unsigned NOT NULL,
  `reqGif` smallint(5) unsigned NOT NULL,
  `reqJpg` smallint(5) unsigned NOT NULL,
  `reqPng` smallint(5) unsigned NOT NULL,
  `reqFont` smallint(5) unsigned NOT NULL,
  `reqFlash` int(4) unsigned NOT NULL,
  `reqJson` int(4) unsigned NOT NULL,
  `reqOther` int(4) unsigned NOT NULL,
  `bytesTotal` int(10) unsigned NOT NULL,
  `bytesHtml` int(10) unsigned NOT NULL,
  `bytesJS` int(10) unsigned NOT NULL,
  `bytesCSS` int(10) unsigned NOT NULL,
  `bytesImg` int(10) unsigned NOT NULL,
  `bytesGif` int(10) unsigned NOT NULL,
  `bytesJpg` int(10) unsigned NOT NULL,
  `bytesPng` int(10) unsigned NOT NULL,
  `bytesFont` int(10) unsigned NOT NULL,
  `bytesFlash` int(10) unsigned NOT NULL,
  `bytesJson` int(10) unsigned NOT NULL,
  `bytesOther` int(10) unsigned NOT NULL,
  `bytesHtmlDoc` mediumint(8) unsigned NOT NULL,
  `numDomains` int(4) unsigned NOT NULL,
  `maxDomainReqs` smallint(5) unsigned NOT NULL,
  `numRedirects` smallint(5) unsigned NOT NULL,
  `numErrors` smallint(5) unsigned NOT NULL,
  `numGlibs` smallint(5) unsigned NOT NULL,
  `numHttps` smallint(5) unsigned NOT NULL,
  `numCompressed` smallint(5) unsigned NOT NULL,
  `numDomElements` mediumint(8) unsigned NOT NULL,
  `maxageNull` smallint(5) unsigned NOT NULL,
  `maxage0` smallint(5) unsigned NOT NULL,
  `maxage1` smallint(5) unsigned NOT NULL,
  `maxage30` smallint(5) unsigned NOT NULL,
  `maxage365` smallint(5) unsigned NOT NULL,
  `maxageMore` smallint(5) unsigned NOT NULL,
  `gzipTotal` int(10) unsigned NOT NULL,
  `gzipSavings` int(10) unsigned NOT NULL,
  `_connections` int(4) unsigned NOT NULL,
  `_adult_site` tinyint(1) NOT NULL,
  PRIMARY KEY (`pageid`),
  UNIQUE KEY `label` (`label`,`urlShort`)
) ENGINE=MyISAM AUTO_INCREMENT=285675 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `crawls`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `crawls` (
  `crawlid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `label` varchar(32) NOT NULL,
  `archive` varchar(32) NOT NULL,
  `location` varchar(32) NOT NULL,
  `notes` varchar(64) DEFAULT NULL,
  `video` tinyint(1) NOT NULL,
  `docComplete` tinyint(1) NOT NULL,
  `fvonly` tinyint(1) NOT NULL,
  `runs` int(4) unsigned DEFAULT NULL,
  `startedDateTime` int(10) unsigned DEFAULT NULL,
  `finishedDateTime` int(10) unsigned DEFAULT NULL,
  `timeOfLastChange` int(10) unsigned NOT NULL,
  `passes` int(2) unsigned DEFAULT NULL,
  `minPageid` int(10) unsigned NOT NULL,
  `maxPageid` int(10) unsigned NOT NULL,
  `numUrls` int(10) unsigned DEFAULT NULL,
  `numErrors` int(10) unsigned DEFAULT NULL,
  `numPages` int(10) unsigned DEFAULT NULL,
  `numRequests` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`crawlid`),
  KEY `label` (`label`,`archive`,`location`)
) ENGINE=MyISAM AUTO_INCREMENT=220 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `urls`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `urls` (
  `timeAdded` int(10) unsigned NOT NULL,
  `urlhash` int(8) unsigned DEFAULT NULL,
  `urlOrig` blob NOT NULL,
  `urlFixed` text,
  `rank` int(10) unsigned DEFAULT NULL,
  `ranktmp` int(10) unsigned DEFAULT NULL,
  `other` tinyint(1) NOT NULL,
  `optout` tinyint(1) NOT NULL,
  PRIMARY KEY (`urlOrig`(255)),
  KEY `urlhash` (`urlhash`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-05-19 10:18:51
