﻿<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">

    <xsl:output method="xml" indent="yes"/>

    <!-- Group body contents -->

    <xsl:template match="doc">
        <doc>
            <xsl:for-each-group select="*" group-starting-with="h1">
                <xsl:choose>
                    <xsl:when test="current-group()[self::h1]">
                        <section lvl="1">
                                <xsl:for-each-group select="current-group()" group-starting-with="h2">
                                    <xsl:choose>
                                        <xsl:when test="current-group()[self::h2]">
                                            <section lvl="2">
                                                <xsl:for-each select="current-group()">
                                                    <xsl:copy-of select="."/>
                                                </xsl:for-each>
                                            </section>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:for-each select="current-group()">
                                                <xsl:copy-of select="."/>
                                            </xsl:for-each>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:for-each-group>
                        </section>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="current-group()">
                            <xsl:copy-of select="."/>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </doc>
    </xsl:template>

</xsl:stylesheet>