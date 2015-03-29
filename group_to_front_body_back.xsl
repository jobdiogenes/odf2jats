﻿<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes="xs"
    version="2.0">

    <xsl:param name="journal-meta-common" select="doc('journal-meta-PP.xml')/journal-meta" as="element(journal-meta)"/>

    <xsl:param name="article-meta-common" select="doc('article-meta-common-PP.xml')/article-meta" as="element(article-meta)"/>

    <xsl:template match="article">
        <article>
            <front>
                <xsl:apply-templates select="$journal-meta-common"/>
                <article-meta>
                    <xsl:apply-templates select="$article-meta-common/article-categories"/>
                    <title-group>
                        <article-title>
                            <xsl:apply-templates select="article-title"/>
                        </article-title>
                    </title-group>
                        <xsl:apply-templates select="authors"/>
                    <pub-date pub-type="pub">
                        <day>____</day>
                        <month>____</month>
                        <year>____</year>
                    </pub-date>
                    <volume>____</volume>
                    <issue>____</issue>
                    <fpage>____</fpage>
                    <lpage>____</lpage>
                    <history>
                        <date date-type="received">
                            <day>____</day>
                            <month>____</month>
                            <year>____</year>
                        </date>
                        <date date-type="accepted">
                            <day>____</day>
                            <month>____</month>
                            <year>____</year>
                        </date>
                    </history>
                    <xsl:apply-templates select="$article-meta-common/permissions"/>
                    <self-uri xlink:href="____">____</self-uri>
                    <xsl:apply-templates select="abstract"/>
                    <kwd-group kwd-group-type="author-generated">
                        <xsl:for-each select="tokenize(keywords, ',')">
                            <kwd><xsl:value-of select="replace(normalize-space(.), '[.]$', '')"/></kwd>
                        </xsl:for-each>
                    </kwd-group>
                </article-meta>
            </front>
            <body>
                <xsl:apply-templates mode="body"/>
            </body>
            <back>
                <ref-list>
                    <xsl:apply-templates select="ref"/>                    
                </ref-list>
            </back>
        </article>
    </xsl:template>

    <xsl:template match="authors">
        <contrib-group>
            <xsl:for-each select="tokenize(., ',')">
            <contrib contrib-type="author">
                <name>
                    <xsl:analyze-string select="normalize-space(.)" regex="\c+$">
                        <xsl:matching-substring>
                            <surname><xsl:value-of select="normalize-space(.)"/></surname>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                            <given-names><xsl:value-of select="normalize-space(.)"/></given-names>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </name>
                <xsl:variable name="aff_rid" select="concat(replace(normalize-space(.) , '^(.).+' , '$1') , '_' , replace( . , '.+\s' , ''))"/>
                <xsl:element name="xref">
                    <xsl:attribute name="ref-type">aff</xsl:attribute>
                    <xsl:attribute name="rid"><xsl:value-of select="$aff_rid"/></xsl:attribute>
                </xsl:element>
            </contrib>    
        </xsl:for-each>
        </contrib-group>
        <!-- One for each author, count commas in authors?: <aff id="____">____</aff> -->
    </xsl:template>

    <xsl:template match="ref">
        <ref>
            <xsl:apply-templates/>
        </ref>
    </xsl:template>

    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="node()|@*" mode="body">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="abstract|keywords|authors|article-title" mode="body"/>
    
</xsl:stylesheet>