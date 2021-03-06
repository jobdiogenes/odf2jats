<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:o2j="https://github.com/eirikhanssen/odf2jats"
    exclude-result-prefixes="xs o2j"
    version="2.0">
    
    <xsl:function name="o2j:monthToInt" as="xs:integer">
        <xsl:param name="monthstring" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($monthstring , '[Jj]an')">1</xsl:when>
            <xsl:when test="matches($monthstring , '[Ff]eb')">2</xsl:when>
            <xsl:when test="matches($monthstring , '[Mm]ar')">3</xsl:when>
            <xsl:when test="matches($monthstring , '[Aa]pr')">4</xsl:when>
            <xsl:when test="matches($monthstring , '[Mm]a[iy]')">5</xsl:when>
            <xsl:when test="matches($monthstring , '[Jj]un')">6</xsl:when>
            <xsl:when test="matches($monthstring , '[Jj]ul')">7</xsl:when>
            <xsl:when test="matches($monthstring , '[Aa]ug')">8</xsl:when>
            <xsl:when test="matches($monthstring , '[Ss]ep')">9</xsl:when>
            <xsl:when test="matches($monthstring , '[Oo][ck]t')">10</xsl:when>
            <xsl:when test="matches($monthstring , '[Nn]ov')">11</xsl:when>
            <xsl:when test="matches($monthstring , '[Dd]e[cs]')">12</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- is this really needed?? -->
    
    <xsl:function name="o2j:replace" as="xs:string">
        <xsl:param name="original_string" as="xs:string"/>
        <xsl:param name="replace_regex" as="xs:string"/>
        <xsl:param name="replacement_string" as="xs:string"/>
        <xsl:variable name="result" as="xs:string*">
            <xsl:analyze-string select="$original_string" regex="{$replace_regex}" >
                <xsl:matching-substring>
                    <xsl:message>
                        <xsl:text>replaced «</xsl:text>
                        <xsl:value-of select="regex-group(0)"/>
                        <xsl:text>» with «</xsl:text>
                        <xsl:value-of select="$replacement_string"/>
                        <xsl:text>»</xsl:text>
                    </xsl:message>
                    <xsl:value-of select="$replacement_string"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:copy/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:value-of select="string-join($result,'')"/>
    </xsl:function>
    
    <xsl:function name="o2j:trimseq" as="xs:string?">
        <!-- take a sequence of nodes, join the string value, trim whitespace and return the resulting string -->
        <xsl:param name="input_seq"/>
        <xsl:variable name="input_string" select='string-join($input_seq, "")'/>
        <xsl:value-of select="o2j:trimstr($input_string)"/>
    </xsl:function>
    
    <xsl:function name="o2j:trimstr" as="xs:string?">
        <!-- take a text input string, trim whitespace and return the resulting string -->
        <xsl:param name="input_string" as="xs:string"/>
        <xsl:variable name="trimmed_edges" select="replace($input_string, '^\s*(.+?)\s*$','$1')"/>
        <xsl:variable name="trimmed_contents" select="replace($trimmed_edges, '[ ]+',' ')"/>
        <xsl:value-of select="$trimmed_contents"/>
    </xsl:function>
    
    <!-- reftext parser functions -->
    
    <xsl:function name="o2j:isAssumedToBeUntaggedReference" as="xs:boolean">
        <xsl:param name="str" as="xs:string"/>
        <xsl:variable name="hasFourDigitsGroup" select="matches($str , '\d{4}')" as="xs:boolean"/>
        <xsl:variable name="hasLetters" select="matches($str , '\c+')" as="xs:boolean"/>
        <xsl:variable name="hasDigitRange" select="matches($str , '\d+\s*(-|–|—|\s)+\s*\d+')"/>
        <xsl:variable name="onlyOneFourDigitsGroup" select="matches($str , '^\D*?\d{4}\D*?$')" as="xs:boolean"></xsl:variable>
        <xsl:variable name="currentYear" select="year-from-date(current-date())" as="xs:integer"/>
        <xsl:variable name="numberInParens" as="xs:integer">
            <xsl:choose>
                <xsl:when test="$onlyOneFourDigitsGroup eq true()">
                    <xsl:variable name="digitsOnly" as="xs:string">
                        <xsl:analyze-string select="$str" regex="\D">
                            <xsl:matching-substring/>
                            <xsl:non-matching-substring>
                                <xsl:copy/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>
                    </xsl:variable>
                    <xsl:value-of select="xs:integer($digitsOnly)"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="xs:integer(0)"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$hasFourDigitsGroup eq false()">
                <!-- All in-text references have 4 digits in a row to refer to a year -->
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when test="$hasDigitRange eq true()">
                <!-- a digit-range in parens should not be considered a reference -->
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when test="matches($str, '^[nN]\s*=\s*\d+$')">
                <xsl:message>
                    <xsl:text>The parens: «(</xsl:text>
                    <xsl:value-of select="$str"/>
                    <xsl:text>)» was not recognized as a citation (probably numeric data). Please check manually.</xsl:text>
                </xsl:message>
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:when test="$onlyOneFourDigitsGroup eq true() and ($numberInParens &lt; ($currentYear - 100) or $numberInParens &gt; $currentYear + 1)">
                <xsl:message>
                    <xsl:text>The parens: «(</xsl:text>
                    <xsl:value-of select="$str"/>
                    <xsl:text>)» was not recognized as a citation (number out of bounds for year). Please check manually.</xsl:text>
                </xsl:message>
                <xsl:value-of select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- if all the other tests failed, then it is probably an untagged reference in the parens -->
                <xsl:value-of select="true()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- reflist parser functions -->
    
    <xsl:function name="o2j:replaceAmpInAuthorstring" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <!-- replace the &amp; (preceeded by comma and optional space) before the last author in authorstring with comma -->
        <!-- then different authors in the authorstring will be separated by (last initial) (dot) (comma) -->
        <xsl:value-of select="replace($originalString, ',*?\s*&amp;' , ',')"/>
    </xsl:function>
    
    <xsl:function name="o2j:normalizeEditorString" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        
        <!--  E.M => E. M -->
        <xsl:variable name="editorStringFix1">
            <xsl:value-of select="replace($originalString , '(\c)\.(\c)' , '$1. $2')"/>
        </xsl:variable>
        
        <!-- Make sure initials have a dot following: E. M => E. M.-->
        <xsl:variable name="editorStringFix2">
            <xsl:value-of select="replace($editorStringFix1 , '\s(\c)\s' , ' $1. ')"/>
        </xsl:variable>
        
        <!-- Replace &amp; surrounded by optional space with comma followed by exactly one space -->
        <!-- E. M. Hanssen &amp; E. De Silva  => E. M. Hanssen, E. De Silva -->
        <xsl:variable name="editorStringFix3">
            <xsl:value-of select="replace($editorStringFix2 , '\s*&amp;\s*' , ', ')"/>
        </xsl:variable>
        
        <xsl:value-of select="$editorStringFix3"/>
    </xsl:function>
    
    <xsl:function name="o2j:normalizeInitialsInAuthorstring" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of
            select="
            normalize-space(
            replace(
            replace(
            replace(
            $originalString , '(\s\c)\s' , '$1. ') ,
            '(\c{3,})(\s\c)' , '$1,$2') ,
            '(\c{3,},\s\c),' , '$1.,')
            )"/>
        <!-- (inner replace) - Correct missing dot after initial: Molander, A => Molander, A. -->
        <!-- (middle replace) - Correct missing comma after surname: Lundberg U. => Lundberg, U. -->
        <!-- (outer replace) - Correct missing dot after initial: Lund, A, = > Lund, A., -->
        <!-- (outer replace) - Correct missing dot after initial: Krantz, J, => Krantz, J., -->
    </xsl:function>
    
    <xsl:function name="o2j:prepareTokens" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <!-- replace comma and whitespace between two authors in authorstring with vertical bar -->
        <xsl:value-of select="replace($originalString, '(\c\.),\s*?' , '$1|')"/>
    </xsl:function>
    
    <xsl:function name="o2j:tokenizeAuthors" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <!-- strip (Ed.). or (Eds.). from authorstring if it is before year in parens -->
        <xsl:variable name="originalStringEdsStripped">
            <xsl:analyze-string select="$originalString" regex="\s*\(Ed[s]?\.?\)\.?\s*">
                <xsl:matching-substring>
                    <xsl:text> </xsl:text><xsl:value-of select="regex-group(1)"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:copy/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        <xsl:value-of select="o2j:prepareTokens(o2j:replaceAmpInAuthorstring(o2j:normalizeInitialsInAuthorstring($originalStringEdsStripped)))"/>
    </xsl:function>
    
    <xsl:function name="o2j:getSurnameFromTokenizedAuthor" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of select="replace($originalString, '^([^,]*),.*$' , '$1')"/>
    </xsl:function>
    
    <xsl:function name="o2j:getGivenNamesFromTokenizedAuthor" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of select="normalize-space(replace($originalString, '^.*,(.*)$' , '$1'))"/>
    </xsl:function>
    
    <xsl:function name="o2j:getSurnameFromTokenizedEditor" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of select="replace($originalString, '.*?\s*([^.]+)$' , '$1')"/>
    </xsl:function>
    
    <xsl:function name="o2j:getGivenNamesFromTokenizedEditor" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of select="normalize-space(replace($originalString, '^((\c\.\s?)+).*?$' , '$1'))"/>
    </xsl:function>
    
    <xsl:function name="o2j:getFirstChar" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of select="replace($originalString, '^(\c).*$' , '$1')"/>
    </xsl:function>
    
    <xsl:function name="o2j:getCaps" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <!-- delete all characters that are not uppercase letters and return string -->
        <xsl:value-of select="replace($originalString, '\P{Lu}' , '')"/>
    </xsl:function>
    
    <xsl:function name="o2j:createRefId" as="xs:string">
        <xsl:param name="authors" as="node()*"/>
        <xsl:param name="year" as="xs:string"/>
        
        <xsl:variable name="authorSurnameCaps">
            <xsl:for-each select="$authors/person-group/name">
                <xsl:value-of select="o2j:getCaps(./surname)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="concat($authorSurnameCaps, $year)"/>
    </xsl:function>
    
    <xsl:function name="o2j:createRefId" as="xs:string">
        <xsl:param name="year" as="xs:string"/>
        <xsl:value-of select="$year"/>
    </xsl:function>
    
    <xsl:function name="o2j:getChapterTitle" as="xs:string">
        <xsl:param name="originalRef" as="node()"/>
        <xsl:variable name="chapterTitle" select="replace($originalRef, '.*?\(\d{4}\c?\)\.?\s*(.+?)\.?\sIn:?\s\p{Lu}\..*', '$1')"/>
        <xsl:value-of select="$chapterTitle"/>
    </xsl:function>
    
    <xsl:function name="o2j:getArticleTitle" as="xs:string">
        <xsl:param name="originalRef" as="element(ref)"/>
        <xsl:variable name="articleTitle" select="replace($originalRef/text()[1], '^.*?\(\d{4}\c?\)\.?\s*(.+?)\s*$', '$1')"/>
        <xsl:value-of select="replace($articleTitle , '^[.\s]*(.+?)$' ,'$1')"/>
    </xsl:function>
    
    <xsl:function name="o2j:getArticleSource" as="xs:string">
        <xsl:param name="originalRef" as="element(ref)"/>
        <xsl:variable name="articleSource" select="replace($originalRef/italic[1], '^(.+?)([,.]\s*\d+.*?)?\s*$', '$1')" as="xs:string"/>
        <xsl:value-of select="replace($articleSource , '^[.\s]*(.+?)$' ,'$1')"/>
    </xsl:function>
    
    <xsl:function name="o2j:getVolume" as="xs:string">
        <xsl:param name="originalRef" as="element(ref)"/>
        <xsl:value-of select="replace($originalRef/italic[1] , '^.*?[,.]\s*(\d+.*?)\s*$' , '$1')"/>
    </xsl:function>
    
    <xsl:function name="o2j:getIssue" as="xs:string">
        <xsl:param name="originalRef" as="element(ref)"/>
        <xsl:value-of select="replace($originalRef/italic[1]/following-sibling::text()[1] , '^\s*\(([\d\c\s/]*?)\).*?$' , '$1')"/>
    </xsl:function>
    
    <xsl:function name="o2j:getArticleIssue" as="xs:integer">
        <xsl:param name="originalRef" as="element(ref)"/>
        <xsl:variable name="articleIssue" select="replace($originalRef/italic[1]/following-sibling::text()[1], '^.*?(\((\d+)\))?.*$', '$2')"/>
        <xsl:value-of select="$articleIssue"/>
    </xsl:function>
    
    <xsl:function name="o2j:getArticlePageRangeSequence" as="element()*">
        <xsl:param name="originalRef" as="element(ref)"/>
        <xsl:variable name="range" as="element()">
            <range>
                <xsl:analyze-string select="$originalRef/italic[1]/following-sibling::text()[1]"
                    regex="(\c?\d+)\s*(-|—|–)\s*(\c?\d+)">
                    <xsl:matching-substring>
                        <fpage><xsl:value-of select="regex-group(1)"/></fpage>
                        <lpage><xsl:value-of select="regex-group(3)"/></lpage>
                    </xsl:matching-substring>
                </xsl:analyze-string>
            </range>
        </xsl:variable>
        <fpage><xsl:value-of select="$range/fpage"/></fpage>
        <lpage><xsl:value-of select="$range/lpage"/></lpage>
    </xsl:function>
    
    <xsl:function name="o2j:getArticleElocationSequence" as="item()*">
        <xsl:param name="originalRef" as="element(ref)"/>
        <xsl:variable name="string_after_italic" select="$originalRef/italic[1]/following-sibling::text()[1]"/>
        <xsl:variable name="uri" select="normalize-space($originalRef/uri[1]/text())" as="xs:string?"/>
        
        <!-- extract elocation-id -->
        <xsl:variable name="elocation" select="replace($string_after_italic, '^\s*(\([-\d\c\s.]+?\))?\s*,?\s*([-_\c\d]+?)\s*\.?\s*$' ,'$2')" as="xs:string?"/>
        
        <!-- get the last n characters of the url, where n equals the length of the elocation string -->
        <xsl:variable name="end_of_uri" select="substring($uri , string-length($uri) +1 - string-length($elocation))" as="xs:string?"/>
        
        <xsl:choose>
            <!-- if $elocation is not empty and matches the end of the uri, be confident that this is indeed the elocation -->
            <xsl:when test="not(empty($elocation)) and compare(xs:string($elocation),xs:string($end_of_uri)) eq 0">
                <elocation-id><xsl:value-of select="$elocation"/></elocation-id>
            </xsl:when>
            <!-- if $elocation is not empty and and doesn't match the end of a uri (that might not even be there), treat as elocation still, but add a comment. -->
            <xsl:when test="not(empty($elocation))">
                <xsl:comment>Please verify that the elocadion-id is indeed an elocation-id and not an uncomplete page range.</xsl:comment>
                <elocation-id><xsl:value-of select="$elocation"/></elocation-id>
                <xsl:message>Please verify that elocation-id: «<xsl:value-of select="$elocation"/>» is indeed an elocation-id and not an uncomplete page range.</xsl:message>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>o2j:getArticleElocationSequence() was called, but did not return elocation-id</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="o2j:stripTranslationFromTitle" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of select="normalize-space(replace($originalString, '^(.*?)\s*\[.*?$', '$1'))"/>
    </xsl:function>
    
    <xsl:function name="o2j:extractTranslationFromTitle" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of select="replace($originalString , '^.*?\[(.+?)\].*$' , '$1')"/>
    </xsl:function>
    
    <xsl:function name="o2j:getSourceTitle" as="xs:string">
        <xsl:param name="originalRef" as="node()"/>
        <xsl:value-of select="normalize-space($originalRef/italic[1])"/>
    </xsl:function>
    
    <xsl:function name="o2j:getTranslatedSource" as="xs:string">
        <xsl:param name="originalRef" as="element(ref)"/>
        <xsl:value-of select="replace($originalRef/italic[1]/following-sibling::text()[1], '^.*?\[([^\]+?])\].*$' , '$1')"/>
    </xsl:function>
    
    <xsl:function name="o2j:getPublisherString" as="xs:string">
        <xsl:param name="originalRef" as="element(ref)"/>
        <!--
      Extract publisher string from a book type reference in a reference list
      This function assumes $originalString to be of a book type reference; a ref that is tested to be $isBook eq true()

      It's important to use the lazy/non-greedy quantifiers such as *? as opposed to *
      to get the shortest possible match and not the longest possible match

      $1 with preceeding regex is important to allow publisher-loc such as {New York, NY: Wiley}

      $2 makes {, } optional, so publisher-loc such as {New York: Basic Books.} is also correctly matched.
      This grouping should not be carried over to the output

      $3 allows forward-slash in publisher-loc as in {Stockholm/Stehag: Symposion.}
      the negated character class [^:] in $3 is important in order to match text only around the last colon
      in the case where a colon might be used earlier in the string

      The last text node of ref is used. This should be ok, as whitespace-only nodes should already 
      have been removed. Maybe this is too naiive, if so, this rule might need to be revisited.
    -->
        <xsl:value-of
            select="normalize-space(replace($originalRef/text()[last()] , '.*?[,.\]]?\s+([^,.\]]*?\c\c+(,\s)?)?([\c/]{2,}:[^:]*?)(\s*Retrieved\s*from\s*)?$' , '$1$3'))"/>
        
    </xsl:function>
    
    <xsl:function name="o2j:getPublisherLoc" as="xs:string">
        <xsl:param name="publisherString" as="xs:string"/>
        <!-- Get all text before colon -->
        <xsl:value-of select="normalize-space(replace($publisherString, '^([^:]*?):.*', '$1'))"/>
    </xsl:function>
    
    <xsl:function name="o2j:getPublisherName" as="xs:string">
        <xsl:param name="publisherString" as="xs:string"/>
        <!-- Get all text after colon, but leave out optional dot in the end -->
        <xsl:value-of select="normalize-space(replace($publisherString, '.*?:([^:]*?)\.?$', '$1'))"/>
    </xsl:function>
    
    <xsl:function name="o2j:getEditorString" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of
            select="replace($originalString , '^.*?\sIn:?\s([^()]*?)[,.\s]*?\((RE|E)ds?\.\).*$' , '$1' )"/>
    </xsl:function>
    
    <xsl:function name="o2j:prepareTokensInEditorString" as="xs:string">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of select="replace($originalString , '(,\s?)' , '|' )"/>
    </xsl:function>
    
    <xsl:function name="o2j:getEdition" as="xs:integer">
        <xsl:param name="originalString" as="xs:string"/>
        <xsl:value-of select="replace($originalString, '^.*?\(\s*(\d+?)\s*(nd|rd|th)\s*ed\.?.*?\).*?$' , '$1')"/>
    </xsl:function>
    
    
    <!-- ref-parser named-templates which is essentially a function, it is called with call-template and works on the context node -->
    
    
    <xsl:template name="ref-parser">

        <xsl:param name="debugmode"/>

        <xsl:variable name="current_ref" select="."/>

        <xsl:variable name="year">
            <xsl:analyze-string select="$current_ref/text()[1]" regex="..*?\((\d{{4}}\c?)\)">
                <xsl:matching-substring>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>

        <xsl:variable name="authors">
            <xsl:analyze-string select="$current_ref/text()[1]" regex="(..*?)\(\d{{4}}\c?\)">
                <xsl:matching-substring>
                    <xsl:value-of select="regex-group(1)"/>
                </xsl:matching-substring>
            </xsl:analyze-string>
        </xsl:variable>

        <xsl:variable name="hasParsableAuthorString" as="xs:boolean">
            <xsl:value-of select="matches($authors, '^\s*[\c][\c]*,\s*[\c]')"/>
        </xsl:variable>

        <xsl:variable name="tokenizedAuthors" as="xs:string">
            <xsl:value-of select="o2j:tokenizeAuthors($authors)"/>
        </xsl:variable>

        <xsl:variable name="hasPublisherLocAndNameString" as="xs:boolean">
            <!-- It is important to make sure that uri elements in the end are not interpreted as publisher-name: publisher-loc (they have colons) -->
            <!-- Check if the end of the reference to see if it ends with a typical reference to a publisher-loc: publisher-name pair -->
            <!-- Allow some flexibility in publisher-name and publisher-loc such as spaces, commas, slash, hyphen -->
            <!-- Example publisher strings that should match:
              Malmö: Liber.
              Cambridge: Polity Press.
              Stockholm/Stehag: Symposion.
              Stockholm: Sveriges Kommuner och Landsting.
              New York: Farrar, Strauss and Giroux.
          -->
            <!--
            This test is very important in classifying book and journal type references and might need to be revisited.
          -->
            <xsl:value-of select="matches($current_ref, '[-\c/]{2,}:\s+[-,\c\s/]{2,}.?$')"/>
        </xsl:variable>

        <xsl:variable name="isBook" as="xs:boolean">
            <!-- all book type references have a publisher-loc: publisher-name pair in the end, optionally followed by an uri -->
            <xsl:value-of select="$hasPublisherLocAndNameString"/>
        </xsl:variable>

        <xsl:variable name="hasTranslatedSource" select="matches($current_ref/italic[1]/following-sibling::text()[1], '^.*?\[(.+?)\].*$')" as="xs:boolean"/>

        <xsl:variable name="hasVolume" select="matches($current_ref/italic[1], '^.*?[,.]\s*\d+.*?\s*$')" as="xs:boolean"/>

        <xsl:variable name="hasIssue" select="matches($current_ref/italic[1]/following-sibling::text()[1], '^\s*?\([\d\c\s/]*?\).*?$')" as="xs:boolean"/>

        <xsl:variable name="isBookChapter" as="xs:boolean">
            <xsl:value-of select="matches($current_ref, '\(\d{4}[a-z]?\).*?((Re|E)ds?\.)')"/>
        </xsl:variable>

        <xsl:variable name="hasTranslatedArticleTitle" select="matches(o2j:getArticleTitle($current_ref), '\[[^\]]+?\]')" as="xs:boolean"/>

        <xsl:variable name="translatedArticleTitle" as="xs:string">
            <xsl:choose>
                <xsl:when test="$hasTranslatedArticleTitle eq true()">
                    <xsl:value-of select="replace(o2j:getArticleTitle($current_ref), '^.*?\[(.+?)\].*$', '$1')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>TranslatedArticleTitleNotFound</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="hasTranslatedBookChapterTitle" select="matches(o2j:getChapterTitle($current_ref), '\[[^\]]+?\]')" as="xs:boolean"/>

        <xsl:variable name="translatedBookChapterTitle" as="xs:string">
            <xsl:choose>
                <xsl:when test="$hasTranslatedBookChapterTitle eq true()">
                    <xsl:value-of select="replace(o2j:getChapterTitle($current_ref), '^.*?\[(.+?)\].*$', '$1')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>TranslatedBookChapterTitleNotFound</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="hasEdition" select="matches($current_ref, '\(\s*\d+?\s*(nd|rd|th)\s*ed\.?.*?\)')" as="xs:boolean"/>

        <xsl:variable name="hasSourceInItalics" as="xs:boolean" select="matches($current_ref/italic[1], '\c+')"/>

        <xsl:variable name="stringBetweenYearInParensAndSourceInItalics" select="replace($current_ref/italic[1]/preceding-sibling::text()[1], '^\D+?\(\s*\d{4}\c?\s*\)(.*?)$', '$1')" as="xs:string"/>

        <xsl:variable name="hasTitleBeforeSourceInItalics" as="xs:boolean" select="matches($stringBetweenYearInParensAndSourceInItalics, '\c+')"/>

        <xsl:variable name="titleBeforeSourceInItalics" as="xs:string">
            <xsl:choose>
                <xsl:when test="$hasTitleBeforeSourceInItalics eq true()">
                    <xsl:value-of select="$stringBetweenYearInParensAndSourceInItalics"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>titleBeforeSourceInItalicsNotFound</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="isJournalArticle" as="xs:boolean">
            <!-- 
            A journal article ref has: 
            parsable authorstring in the beginning followed by year in parens
            article-title between year in parens after author string and source in italics (name of journal)
            name of journal in italics
    
            A journal article does not have:
            publisher-loc: publisher-name in the end
          -->
            <xsl:value-of select="$hasTitleBeforeSourceInItalics eq true() and $hasSourceInItalics eq true() and $isBook eq false()"/>
        </xsl:variable>

        <xsl:variable name="hasArticlePageRange" select="$isJournalArticle and matches($current_ref/italic[1]/following-sibling::text()[1], '^.*?(\c?\d+\s*(-|—|–)\s*\c?\d+).*?$')" as="xs:boolean"/>

        <xsl:variable name="hasElocationCandidate" select="$isJournalArticle and matches($current_ref/italic[1]/following-sibling::text()[1], '^\s*(\([-\d\c\s.]+\))?\s*,?\s*(\c?\d+\s*\c?)\s*\.?\s*$')" as="xs:boolean"/>

        <xsl:variable name="hasSinglePageCountStringInParens" as="xs:boolean">
            <xsl:value-of select="matches($current_ref, '\(.*?p?p\.\s*\d+.*?\)') and not(matches($current_ref, '\(.*?pp\.\s*\d+\s*-\s*\d+.*?\)'))"/>
        </xsl:variable>

        <xsl:variable name="hasMultiplePageCountStringInParens" as="xs:boolean">
            <xsl:value-of select="matches($current_ref, '\(.*?pp\.\s*\c?\d+\s*(-|—|–)\s*\c?\d+.*?\)')"/>
        </xsl:variable>

        <xsl:variable name="editorString">
            <xsl:if test="$isBookChapter eq true()">
                <xsl:value-of select="normalize-space(o2j:getEditorString($current_ref))"/>
            </xsl:if>
        </xsl:variable>

        <xsl:variable name="tokenizedEditors" as="xs:string">
            <xsl:value-of select="o2j:prepareTokensInEditorString(o2j:normalizeEditorString($editorString))"/>
        </xsl:variable>

        <xsl:variable name="isParsableEditorString" as="xs:boolean">
            <xsl:value-of select="
                    matches(
                    o2j:normalizeEditorString($editorString),
                    '((\c.\s)+([-\c]{2,}(,|\s)?)+)'
                    )"/>
        </xsl:variable>

        <!-- WIP placeholder hasParsablePublisherString  -->

        <!-- WIP placeholder isParsablePublisherString -->

        <xsl:variable name="hasYearInParanthesis" as="xs:boolean">
            <xsl:value-of select='matches($current_ref, ".*\(\d{4}\c?\).*")'/>
        </xsl:variable>

        <!-- unknown ref types will be marked up as mixed citation, that means all ref types that
        will not be automatically identified as either book, book-chapter or journal article -->
        <!-- WIP this test needs to be revisited -->
        <xsl:variable name="isUnknownRefType" as="xs:boolean">
            <xsl:value-of select="not($hasYearInParanthesis and $hasParsableAuthorString) or not($isBook or $isJournalArticle)"/>
        </xsl:variable>

        <xsl:variable name="taggedAuthors">
            <xsl:choose>
                <xsl:when test="$hasParsableAuthorString eq true()">
                    <!-- process $authors -->
                    <xsl:variable name="person-group-type" as="xs:string">
                        <xsl:choose>
                            <!-- 
                    the editors of the book will be listed, followed by (Eds.). before year in parens
                    if the reference in question is the whole edited book. If so, appropriately use the 
                    right attribute value for person-group-type
                  -->
                            <xsl:when test="matches($authors, '\(Ed[s]\.?\)')">
                                <xsl:text>editor</xsl:text>
                            </xsl:when>
                            <xsl:otherwise>author</xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <person-group person-group-type="author">
                        <xsl:attribute name="person-group-type" select="$person-group-type"/>
                        <xsl:for-each select="tokenize($tokenizedAuthors, '\|')">
                            <xsl:variable name="author" select="normalize-space(.)"/>
                            <name>
                                <surname>
                                    <xsl:value-of select="o2j:getSurnameFromTokenizedAuthor($author)"/>
                                </surname>
                                <given-names>
                                    <xsl:value-of select="o2j:getGivenNamesFromTokenizedAuthor($author)"/>
                                </given-names>
                            </name>
                        </xsl:for-each>
                    </person-group>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="taggedEditors">
            <xsl:choose>
                <xsl:when test="$isParsableEditorString eq true()">
                    <person-group person-group-type="editor">
                        <xsl:for-each select="tokenize($tokenizedEditors, '\|')">
                            <xsl:variable name="editor" select="normalize-space(.)"/>
                            <name>
                                <surname>
                                    <xsl:value-of select="o2j:getSurnameFromTokenizedEditor($editor)"/>
                                </surname>
                                <given-names>
                                    <xsl:value-of select="o2j:getGivenNamesFromTokenizedEditor($editor)"/>
                                </given-names>
                            </name>
                        </xsl:for-each>
                    </person-group>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="publisher">
            <xsl:choose>
                <xsl:when test="$isBook eq true()">
                    <publisher-loc>
                        <xsl:value-of select="o2j:getPublisherLoc(o2j:getPublisherString($current_ref))"/>
                    </publisher-loc>
                    <publisher-name>
                        <xsl:value-of select="o2j:getPublisherName(o2j:getPublisherString($current_ref))"/>
                    </publisher-name>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="publication-info">
            <attributes>
                <!-- publication-type: book-chapter|book|journal -->
                <xsl:if test="$isBook eq true() or $isBookChapter eq true() or $isJournalArticle eq true()">
                    <xsl:attribute name="publication-type">
                        <xsl:choose>
                            <xsl:when test="$isBook eq true()">
                                <xsl:choose>
                                    <xsl:when test="$isBookChapter eq true()">
                                        <xsl:text>book-chapter</xsl:text>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:text>book</xsl:text>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:when test="$isJournalArticle">
                                <xsl:text>journal</xsl:text>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:attribute>
                </xsl:if>

                <!-- publication-format: print|web -->
                <xsl:attribute name="publication-format">
                    <xsl:choose>
                        <xsl:when test="uri">
                            <xsl:text>web</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>print</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </attributes>
        </xsl:variable>

        <xsl:element name="ref">
            <xsl:attribute name="id">
                <xsl:choose>
                    <xsl:when test="$isUnknownRefType eq false()">
                        <xsl:value-of select="o2j:createRefId($taggedAuthors, $year)"/>
                    </xsl:when>
                    <xsl:when test="$hasYearInParanthesis eq true()">
                        <xsl:text>___</xsl:text>
                        <xsl:value-of select="$year"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>___</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>

            <!-- The original, unchanged reference will be inserted in a comment to compare with the autotagged text -->
            <xsl:comment><xsl:apply-templates mode="comment"/></xsl:comment>

            <xsl:choose>
                <xsl:when test="$isUnknownRefType eq true()">
                    <xsl:element name="mixed-citation">
                        <xsl:copy-of select="$publication-info/attributes/@*"/>
                        <xsl:apply-templates/>
                    </xsl:element>
                </xsl:when>

                <xsl:when test="$isUnknownRefType eq false()">
                    <xsl:element name="element-citation">
                        <xsl:copy-of select="$publication-info/attributes/@*"/>
                        <xsl:apply-templates select="$taggedAuthors"/>
                        <year>
                            <xsl:value-of select="$year"/>
                        </year>
                        <xsl:choose>
                            <xsl:when test="$isBook eq true()">
                                <xsl:choose>
                                    <xsl:when test="$isBookChapter eq true()">
                                        <chapter-title>
                                            <xsl:choose>
                                                <xsl:when test="$hasTranslatedBookChapterTitle eq true()">
                                                    <xsl:attribute name="xml:lang">__</xsl:attribute>
                                                    <!-- remove translation in angle brackets -->
                                                    <xsl:value-of select="o2j:stripTranslationFromTitle(o2j:getChapterTitle($current_ref))"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="o2j:getChapterTitle($current_ref)"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </chapter-title>
                                        <xsl:if test="$hasTranslatedBookChapterTitle eq true()">
                                            <trans-title>
                                                <xsl:attribute name="xml:lang">__</xsl:attribute>
                                                <!-- extract only the translation in angle brackets -->
                                                <xsl:value-of select="$translatedBookChapterTitle"/>
                                            </trans-title>
                                        </xsl:if>
                                        <xsl:apply-templates select="$taggedEditors"/>
                                        <source>
                                            <xsl:if test="$hasTranslatedSource eq true()">
                                                <xsl:attribute name="xml:lang">__</xsl:attribute>
                                            </xsl:if>
                                            <xsl:value-of select="o2j:getSourceTitle($current_ref)"/>
                                        </source>
                                        <xsl:if test="$hasTranslatedSource eq true()">
                                            <trans-source>
                                                <xsl:attribute name="xml:lang">__</xsl:attribute>
                                                <xsl:value-of select="replace($current_ref/italic[1]/following-sibling::text()[1], '^.*?\[(.+?)\].*$', '$1')"/>
                                            </trans-source>
                                        </xsl:if>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <source>
                                            <xsl:if test="$hasTranslatedSource eq true()">
                                                <xsl:attribute name="xml:lang">__</xsl:attribute>
                                            </xsl:if>
                                            <xsl:value-of select="o2j:getSourceTitle($current_ref)"/>
                                        </source>
                                        <xsl:if test="$hasTranslatedSource eq true()">
                                            <trans-source>
                                                <xsl:attribute name="xml:lang">__</xsl:attribute>
                                                <!-- extract only the translation in angle brackets -->
                                                <xsl:value-of select="replace($current_ref/italic[1]/following-sibling::text()[1], '^.*?\[(.+?)\].*$', '$1')"/>
                                            </trans-source>
                                        </xsl:if>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <!-- insert edition if present in reference -->
                                <xsl:if test="$hasEdition eq true()">
                                    <edition>
                                        <xsl:value-of select="o2j:getEdition($current_ref)"/>
                                    </edition>
                                </xsl:if>
                            </xsl:when>

                            <xsl:when test="$isJournalArticle eq true()">
                                <article-title>
                                    <xsl:choose>
                                        <xsl:when test="$hasTranslatedArticleTitle eq true()">
                                            <xsl:attribute name="xml:lang">__</xsl:attribute>
                                            <xsl:value-of select="o2j:stripTranslationFromTitle(o2j:getArticleTitle($current_ref))"/>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of select="o2j:getArticleTitle($current_ref)"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </article-title>

                                <xsl:if test="$hasTranslatedArticleTitle eq true()">
                                    <trans-title>
                                        <xsl:attribute name="xml:lang">__</xsl:attribute>
                                        <!-- extract only the translation in angle brackets -->
                                        <xsl:value-of select="o2j:extractTranslationFromTitle(o2j:getArticleTitle($current_ref))"/>
                                    </trans-title>
                                </xsl:if>

                                <source>
                                    <xsl:if test="$hasTranslatedSource eq true()">
                                        <xsl:attribute name="xml:lang">__</xsl:attribute>
                                    </xsl:if>
                                    <xsl:value-of select="o2j:getArticleSource($current_ref)"/>
                                </source>
                                <xsl:if test="$hasTranslatedSource eq true()">
                                    <trans-source>
                                        <xsl:attribute name="xml:lang">__</xsl:attribute>
                                        <xsl:value-of select="o2j:getTranslatedSource($current_ref)"/>
                                    </trans-source>
                                </xsl:if>

                                <xsl:if test="$hasVolume eq true()">
                                    <volume><xsl:value-of select="o2j:getVolume($current_ref)"/></volume>
                                </xsl:if>

                                <xsl:if test="$hasIssue eq true()">
                                    <issue><xsl:value-of select="o2j:getIssue($current_ref)"/></issue>
                                </xsl:if>

                                <xsl:if test="$hasArticlePageRange eq true()">
                                    <xsl:sequence select="o2j:getArticlePageRangeSequence($current_ref)"/>
                                </xsl:if>

                                <xsl:if test="$hasElocationCandidate eq true()">
                                    <xsl:sequence select="o2j:getArticleElocationSequence($current_ref)"/>
                                </xsl:if>

                            </xsl:when>
                        </xsl:choose>

                        <xsl:choose>
                            <xsl:when test="$hasMultiplePageCountStringInParens eq true()">
                                <fpage><xsl:value-of select="replace($current_ref, '.*?\(.*?pp\.\s*(\c?\d+)\s*(-|—|–)\s*\c?\d+.*?\).*', '$1')"/></fpage>
                                <lpage><xsl:value-of select="replace($current_ref, '.*?\(.*?pp\.\s*\c?\d+\s*(-|—|–)\s*(\c?\d+).*?\).*', '$2')"/></lpage>
                            </xsl:when>
                            <xsl:when test="$hasSinglePageCountStringInParens eq true()">
                                <fpage><xsl:value-of select="replace($current_ref, '.*?\(.*?p?p\.\s*(\d+).*?\).*', '$1')"/></fpage>
                            </xsl:when>
                        </xsl:choose>

                        <xsl:if test="$isBook eq true()">
                            <publisher-loc><xsl:value-of select="$publisher/publisher-loc"/></publisher-loc>
                            <publisher-name><xsl:value-of select="$publisher/publisher-name"/></publisher-name>
                        </xsl:if>

                        <xsl:if test="uri">
                            <xsl:sequence select="uri"/>
                        </xsl:if>
                    </xsl:element>
                    
                </xsl:when>
                <xsl:otherwise>
                    <errorInXSLT/>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:if test="$debugmode eq true()">
                <xsl:text>&#xa;</xsl:text>
                <debugMode>
                    <debug>On</debug>
                    <originalRef>
                        <xsl:apply-templates/>
                    </originalRef>
                    <authors>
                        <xsl:value-of select="$authors"/>
                    </authors>
                    <tokenizedAuthors>
                        <xsl:value-of select="$tokenizedAuthors"/>
                    </tokenizedAuthors>
                    <editorstring>
                        <xsl:value-of select="$editorString"/>
                    </editorstring>
                    <normalizedEditorString>
                        <xsl:value-of select="o2j:normalizeEditorString($editorString)"/>
                    </normalizedEditorString>
                    <parsableEditorString>
                        <xsl:value-of select="$isParsableEditorString"/>
                    </parsableEditorString>
                    <tokenizedEditorString>
                        <xsl:value-of select="o2j:prepareTokensInEditorString(o2j:normalizeEditorString($editorString))"/>
                    </tokenizedEditorString>
                    <publisherString>
                        <xsl:value-of select="o2j:getPublisherString($current_ref)"/>
                    </publisherString>
                </debugMode>
            </xsl:if>

        </xsl:element>

    </xsl:template>
    
</xsl:stylesheet>