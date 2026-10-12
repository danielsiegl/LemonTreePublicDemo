<?xml version="1.0" encoding="utf-8"?>
<!--
  LemonTree Diff Report  ·  MARKDOWN DASHBOARD (GitHub PR Comment)
  ================================================================
  Transforms a LemonTree ChangeReport (schema 1.4) into GitHub-Flavored
  Markdown optimized for GitHub Pull Request comments.

  · Header with model comparison metadata (Base vs Head, commits, author, date)
  · Unified changes by package table (including overall Total row)
  · Collapsible list of all changed elements

  Companion stylesheets:
  · LemonTreeDiffDashboard.xsl (HTML dashboard)
  · LemonTreeDiffReport.xsl (HTML document)
-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:cr="http://www.lieberlieber.com"
                exclude-result-prefixes="cr">

  <xsl:output method="text" encoding="utf-8"/>

  <xsl:variable name="propertiesToHide">,OwnedBehaviors,End_Edge,ConnectedElement,Target,Incomings,Outgoings,GraphEdges,GraphNodes,WayPoints,Type,ObjectStyle::LBL,PDATA5,PtEndX,PtEndY,PtStartX,PtStartY,RectBottom,RectLeft,RectRight,RectTop,SeqNo,Start_Edge,StateFlags,Style,StyleEx,</xsl:variable>
  <xsl:variable name="elementsToHide">,ConnectorEnd,ea_DiagramLink,ea_DiagramObject,</xsl:variable>

  <xsl:variable name="visibleElements"
                select="//cr:element[not(contains($elementsToHide, concat(',', @umlType, ',')))]
                                    [count(cr:changedProperties/cr:property) = 0
                                     or count(cr:changedProperties/cr:property[not(contains($propertiesToHide, @name))]) &gt; 0]"/>

  <xsl:key name="byType" match="cr:element" use="@eaUmlType"/>

  <!-- state classification usable inside XPath -->
  <xsl:variable name="eNew"      select="$visibleElements[contains(@diffState, 'New')]"/>
  <xsl:variable name="eRemoved"  select="$visibleElements[contains(@diffState, 'Removed') and not(contains(@diffState, 'New'))]"/>
  <xsl:variable name="eMoved"    select="$visibleElements[contains(@diffState, 'Moved') and not(contains(@diffState, 'New')) and not(contains(@diffState, 'Removed'))]"/>
  <xsl:variable name="eModified" select="$visibleElements[(starts-with(@diffState, 'Modified') or contains(@diffState, 'Modified,')) and not(contains(@diffState, 'New')) and not(contains(@diffState, 'Removed')) and not(contains(@diffState, 'Moved'))]"/>
  <xsl:variable name="eSub"      select="$visibleElements[contains(@diffState, 'SubElementModified') and not(starts-with(@diffState, 'Modified')) and not(contains(@diffState, 'Modified,')) and not(contains(@diffState, 'New')) and not(contains(@diffState, 'Removed')) and not(contains(@diffState, 'Moved'))]"/>
  <xsl:variable name="suspectedLinks" select="$visibleElements[cr:connectedElements/cr:connectedElement][cr:changedProperties/cr:property[@name = 'Stereotypes' and contains(@newValue, 'suspected{LemonTree Connect::suspected}:Stereotype') and not(contains(@oldValue, 'suspected{LemonTree Connect::suspected}:Stereotype'))]]"/>

  <!-- ====================================================================== -->
  <!-- Helpers                                                                -->
  <!-- ====================================================================== -->

  <xsl:template name="stateBadge">
    <xsl:param name="state"/>
    <xsl:choose>
      <xsl:when test="contains($state, 'New')">&#128994; New</xsl:when>
      <xsl:when test="contains($state, 'Removed')">&#128308; Removed</xsl:when>
      <xsl:when test="contains($state, 'Moved')">&#128309; Moved</xsl:when>
      <xsl:when test="$state = 'SubElementModified'">&#128995; Child Modified</xsl:when>
      <xsl:when test="contains($state, 'Modified')">&#128993; Modified</xsl:when>
      <xsl:otherwise><xsl:value-of select="$state"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="substring-after-last">
    <xsl:param name="string"/>
    <xsl:param name="delimiter"/>
    <xsl:choose>
      <xsl:when test="contains($string, $delimiter)">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="string" select="substring-after($string, $delimiter)"/>
          <xsl:with-param name="delimiter" select="$delimiter"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$string"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="escapePipes">
    <xsl:param name="text"/>
    <xsl:choose>
      <xsl:when test="contains($text, '|')">
        <xsl:value-of select="substring-before($text, '|')"/>
        <xsl:text>\|</xsl:text>
        <xsl:call-template name="escapePipes">
          <xsl:with-param name="text" select="substring-after($text, '|')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Display name of an element -->
  <xsl:template name="displayName">
    <xsl:variable name="rawName">
      <xsl:choose>
        <xsl:when test="normalize-space(@ltName) != ''"><xsl:value-of select="@ltName"/></xsl:when>
        <xsl:when test="normalize-space(@name) != ''"><xsl:value-of select="@name"/></xsl:when>
        <xsl:otherwise>
          <xsl:variable name="last">
            <xsl:call-template name="substring-after-last">
              <xsl:with-param name="string" select="@qualifiedName"/>
              <xsl:with-param name="delimiter" select="'.'"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="normalize-space($last) != ''"><xsl:value-of select="$last"/></xsl:when>
            <xsl:otherwise>[unnamed]</xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="escapePipes">
      <xsl:with-param name="text" select="$rawName"/>
    </xsl:call-template>
  </xsl:template>

  <!-- 2026-09-09T18:17:23 → 2026-09-09 18:17 -->
  <xsl:template name="niceDate">
    <xsl:param name="d"/>
    <xsl:value-of select="translate(substring($d, 1, 16), 'T', ' ')"/>
  </xsl:template>

  <!-- ====================================================================== -->
  <!-- Root Template                                                          -->
  <!-- ====================================================================== -->
  <xsl:template match="/cr:report">
    <xsl:variable name="cNew" select="count($eNew)"/>
    <xsl:variable name="cRemoved" select="count($eRemoved)"/>
    <xsl:variable name="cModified" select="count($eModified)"/>
    <xsl:variable name="cSub" select="count($eSub)"/>
    <xsl:variable name="cMoved" select="count($eMoved)"/>
    <xsl:variable name="cAll" select="count($visibleElements)"/>
    <xsl:variable name="cPackages" select="count(cr:changes/cr:package)"/>
    <xsl:variable name="cProps" select="count($visibleElements/cr:changedProperties/cr:property[not(contains($propertiesToHide, @name))])"/>
    <xsl:variable name="cSuspected" select="count($suspectedLinks)"/>

<xsl:if test="$cSuspected &gt; 0">
<xsl:text>## ⚠️ Suspected Traceability Links&#10;&#10;</xsl:text>
<xsl:text>**</xsl:text>
<xsl:value-of select="$cSuspected"/>
<xsl:text> traceability link</xsl:text>
<xsl:if test="$cSuspected != 1"><xsl:text>s</xsl:text></xsl:if>
<xsl:text> marked as suspected. Review these links before merging.**&#10;&#10;</xsl:text>
<xsl:text>| Type | Package | Name |&#10;</xsl:text>
<xsl:text>| :--- | :--- | :--- |&#10;</xsl:text>
<xsl:for-each select="$suspectedLinks">
  <xsl:sort select="ancestor::cr:package/@qualifiedName"/>
  <xsl:sort select="@qualifiedName"/>
  <xsl:variable name="stereotypesProperty" select="cr:changedProperties/cr:property[@name = 'Stereotypes'][1]"/>
  <xsl:variable name="linkTypeSource">
    <xsl:choose>
      <xsl:when test="contains($stereotypesProperty/@oldValue, '{')"><xsl:value-of select="$stereotypesProperty/@oldValue"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$stereotypesProperty/@newValue"/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:text>| `</xsl:text>
  <xsl:choose>
    <xsl:when test="contains($linkTypeSource, '{')"><xsl:value-of select="substring-before($linkTypeSource, '{')"/></xsl:when>
    <xsl:when test="@eaUmlType != ''"><xsl:value-of select="@eaUmlType"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="@umlType"/></xsl:otherwise>
  </xsl:choose>
  <xsl:text>` | `</xsl:text>
  <xsl:call-template name="escapePipes">
    <xsl:with-param name="text" select="ancestor::cr:package/@name"/>
  </xsl:call-template>
  <xsl:text>` | </xsl:text>
  <xsl:call-template name="displayName"/>
  <xsl:text> |&#10;</xsl:text>
</xsl:for-each>
<xsl:text>&#10;</xsl:text>
</xsl:if>

<!-- Unified Changes by Package Table -->
<xsl:text>### 📊 Changes by Package&#10;&#10;</xsl:text>
<xsl:text>| Package | Changes | &#128994; New | &#128993; Modified | &#128308; Removed | &#128309; Moved | &#128995; Child Modified |&#10;</xsl:text>
<xsl:text>| :--- | :---: | :---: | :---: | :---: | :---: | :---: |&#10;</xsl:text>
<xsl:for-each select="cr:changes/cr:package">
  <xsl:sort select="count(.//cr:element[count(.|$visibleElements) = count($visibleElements)])" data-type="number" order="descending"/>
  <xsl:variable name="mine" select=".//cr:element[count(.|$visibleElements) = count($visibleElements)]"/>
  <xsl:variable name="n" select="count($mine)"/>
  <xsl:if test="$n &gt; 0">
    <xsl:variable name="pNew" select="count($mine[contains(@diffState, 'New')])"/>
    <xsl:variable name="pRem" select="count($mine[contains(@diffState, 'Removed') and not(contains(@diffState, 'New'))])"/>
    <xsl:variable name="pMov" select="count($mine[contains(@diffState, 'Moved') and not(contains(@diffState, 'New')) and not(contains(@diffState, 'Removed'))])"/>
    <xsl:variable name="pMod" select="count($mine[(starts-with(@diffState, 'Modified') or contains(@diffState, 'Modified,')) and not(contains(@diffState, 'New')) and not(contains(@diffState, 'Removed')) and not(contains(@diffState, 'Moved'))])"/>
    <xsl:variable name="pSub" select="count($mine[contains(@diffState, 'SubElementModified') and not(starts-with(@diffState, 'Modified')) and not(contains(@diffState, 'Modified,')) and not(contains(@diffState, 'New')) and not(contains(@diffState, 'Removed')) and not(contains(@diffState, 'Moved'))])"/>
    <xsl:text>| `</xsl:text>
    <xsl:call-template name="escapePipes">
      <xsl:with-param name="text" select="@name"/>
    </xsl:call-template>
    <xsl:text>` | </xsl:text>
    <xsl:value-of select="$n"/>
    <xsl:text> | </xsl:text>
    <xsl:value-of select="$pNew"/>
    <xsl:text> | </xsl:text>
    <xsl:value-of select="$pMod"/>
    <xsl:text> | </xsl:text>
    <xsl:value-of select="$pRem"/>
    <xsl:text> | </xsl:text>
    <xsl:value-of select="$pMov"/>
    <xsl:text> | </xsl:text>
    <xsl:value-of select="$pSub"/>
    <xsl:text> |&#10;</xsl:text>
  </xsl:if>
</xsl:for-each>
<xsl:text>| **Total** | **</xsl:text>
<xsl:value-of select="$cAll"/>
<xsl:text>** | **</xsl:text>
<xsl:value-of select="$cNew"/>
<xsl:text>** | **</xsl:text>
<xsl:value-of select="$cModified"/>
<xsl:text>** | **</xsl:text>
<xsl:value-of select="$cRemoved"/>
<xsl:text>** | **</xsl:text>
<xsl:value-of select="$cMoved"/>
<xsl:text>** | **</xsl:text>
<xsl:value-of select="$cSub"/>
<xsl:text>** |&#10;&#10;</xsl:text>

<!-- Collapsible Changed Elements List -->
<xsl:if test="$cAll &gt; 0">
<xsl:text>&lt;details&gt;&#10;&lt;summary&gt;&lt;b&gt;📋 All Changed Elements (</xsl:text>
<xsl:value-of select="$cAll"/>
<xsl:text>)&lt;/b&gt;&lt;/summary&gt;&#10;&#10;</xsl:text>
<xsl:text>| State | Type | Name | Package |&#10;</xsl:text>
<xsl:text>| :--- | :--- | :--- | :--- |&#10;</xsl:text>
<xsl:for-each select="$visibleElements">
  <xsl:sort select="ancestor::cr:package/@qualifiedName"/>
  <xsl:sort select="@qualifiedName"/>
  <xsl:text>| </xsl:text>
  <xsl:call-template name="stateBadge">
    <xsl:with-param name="state" select="@diffState"/>
  </xsl:call-template>
  <xsl:text> | `</xsl:text>
  <xsl:choose>
    <xsl:when test="@eaUmlType != ''"><xsl:value-of select="@eaUmlType"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="@umlType"/></xsl:otherwise>
  </xsl:choose>
  <xsl:text>` | </xsl:text>
  <xsl:call-template name="displayName"/>
  <xsl:text> | `</xsl:text>
  <xsl:call-template name="escapePipes">
    <xsl:with-param name="text" select="ancestor::cr:package/@name"/>
  </xsl:call-template>
  <xsl:text>` |&#10;</xsl:text>
</xsl:for-each>
<xsl:text>&#10;&lt;/details&gt;&#10;&#10;</xsl:text>
</xsl:if>

<xsl:text>---&#10;</xsl:text>
<xsl:text>*Generated by LemonTree.Automation </xsl:text>
<xsl:value-of select="@creatorVersion"/>
<xsl:text>*</xsl:text>
<xsl:text>&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>