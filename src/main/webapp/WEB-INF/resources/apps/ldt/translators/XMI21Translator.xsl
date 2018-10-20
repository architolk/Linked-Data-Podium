<!--

    NAME     XMI21Translator.xsl
    VERSION  1.23.0
    DATE     2018-10-20

    Copyright 2012-2018

    This file is part of the Linked Data Theatre.

    The Linked Data Theatre is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    The Linked Data Theatre is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.

-->
<!--
    DESCRIPTION
	Translates XMI2.1 to corresponding linked data (uml schema)
	
-->
<xsl:stylesheet version="2.0"
	xmlns:xmi="http://schema.omg.org/spec/XMI/2.1"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:RGB="http://www.sparxsystems.com/profiles/RGB/1.0#"
	xmlns:uml="http://schema.omg.org/spec/UML/2.1.1#"
	xmlns:uml211="http://schema.omg.org/spec/UML/2.1.1"
	xmlns:uml21="http://schema.omg.org/spec/UML/2.1"
	xmlns:ea="http://www.sparxsystems.com/extender/EA6.5#"
>
	
<xsl:output method="xml" indent="yes"/>

<xsl:variable name="domain">uuid:</xsl:variable>

<xsl:template name="explore-properties">
	<!-- Some attributes are properties -->
	<xsl:if test="exists(@name)">
		<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
	</xsl:if>
	<xsl:if test="exists(@body)">
		<uml:body><xsl:value-of select="@body"/></uml:body>
	</xsl:if>
	<xsl:if test="exists(@supplier)">
		<uml:supplier>
			<xsl:variable name="id" select="@supplier"/>
			<xsl:attribute name="rdf:resource"><xsl:value-of select="$domain"/><xsl:value-of select="$id"/></xsl:attribute>
		</uml:supplier>
	</xsl:if>
	<xsl:if test="exists(@client)">
		<uml:client>
			<xsl:variable name="id" select="@client"/>
			<xsl:attribute name="rdf:resource"><xsl:value-of select="$domain"/><xsl:value-of select="$id"/></xsl:attribute>
		</uml:client>
	</xsl:if>
	<xsl:if test="exists(@general)">
		<uml:general>
			<xsl:variable name="id" select="@general"/>
			<xsl:attribute name="rdf:resource"><xsl:value-of select="$domain"/><xsl:value-of select="$id"/></xsl:attribute>
		</uml:general>
	</xsl:if>
	<xsl:if test="exists(@association)">
		<uml:association>
			<xsl:variable name="id" select="@association"/>
			<xsl:attribute name="rdf:resource"><xsl:value-of select="$domain"/><xsl:value-of select="$id"/></xsl:attribute>
		</uml:association>
	</xsl:if>
	<!-- Elements are properties -->
	<xsl:for-each select="*">
		<xsl:variable name="property" select="local-name(.)"/>
		<xsl:element name="uml:{$property}">
			<xsl:choose>
				<xsl:when test="exists(@value)">
					<xsl:value-of select="@value"/>
				</xsl:when>
				<xsl:when test="@xmi:idref!=''">
					<xsl:variable name="id" select="@xmi:idref"/>
					<xsl:attribute name="rdf:resource"><xsl:value-of select="$domain"/><xsl:value-of select="$id"/></xsl:attribute>
				</xsl:when>
				<xsl:when test="@xmi:id!=''">
					<xsl:variable name="id" select="@xmi:id"/>
					<xsl:attribute name="rdf:resource"><xsl:value-of select="$domain"/><xsl:value-of select="$id"/></xsl:attribute>
				</xsl:when>
				<xsl:when test="local-name(.)='body'"><xsl:value-of select="."/></xsl:when>
				<xsl:when test="local-name(.)='language'"><xsl:value-of select="."/></xsl:when>
				<xsl:otherwise>Unexplored (<xsl:value-of select="local-name(.)"/>)</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
	</xsl:for-each>
</xsl:template>

<xsl:template match="uml211:Model|uml21:Model">
	<xsl:element name="{@xmi:type}">
		<xsl:variable name="id">EAModel</xsl:variable>
		<xsl:attribute name="rdf:about"><xsl:value-of select="$domain"/><xsl:value-of select="$id"/></xsl:attribute>
		<xsl:call-template name="explore-properties"/>

	</xsl:element>
	
	<xsl:apply-templates select="*[exists(@xmi:type)]"/>
</xsl:template>

<!--Catch all xmi:id-->
<xsl:template match="*[exists(@xmi:id)]">
	<!-- Wel een id, geen type, dan nu ff overslaan (beter zou zijn om dit te loggen) -->
	<xsl:if test="exists(@xmi:type)">
		<xsl:element name="{@xmi:type}">
			<xsl:variable name="id" select="@xmi:id"/>
			<xsl:attribute name="rdf:about"><xsl:value-of select="$domain"/><xsl:value-of select="$id"/></xsl:attribute>

			<xsl:call-template name="explore-properties"/>
			
		</xsl:element>
	</xsl:if>
	
	<xsl:apply-templates select="*[exists(@xmi:type)]"/>
</xsl:template>

<!--Catch all extensions -->
<xsl:template match="*[exists(@base_Class)]">
	<xsl:element name="RGB:{local-name(.)}">
		<xsl:variable name="id" select="@base_Class"/>
		<xsl:attribute name="rdf:about"><xsl:value-of select="$domain"/><xsl:value-of select="$id"/></xsl:attribute>
		
		<xsl:for-each select="@*">
			<xsl:variable name="name" select="name(.)"/>
			<xsl:variable name="value" select="."/>
			<xsl:if test="$name!='base_Class'">
				<xsl:element name="RGB:{$name}">
					<xsl:value-of select="$value"/>
				</xsl:element>
			</xsl:if>
		</xsl:for-each>
		
	</xsl:element>
</xsl:template>

<!-- Catch all extensions via xmi:Extension -->
<xsl:template match="element" mode="extension">
	<!-- Weird something in EA: if a property package2 exists, the ID is hidden in this property... -->
	<xsl:variable name="id">
		<xsl:choose>
			<xsl:when test="model/@package2!=''"><xsl:value-of select="replace(model/@package2,'^EAID','EAPK')"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="@xmi:idref"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<rdf:Description rdf:about="{$domain}{$id}">
		<xsl:for-each select="properties/@*">
			<xsl:element name="ea:{local-name(.)}"><xsl:value-of select="."/></xsl:element>
		</xsl:for-each>
		<xsl:for-each select="project/@*"> <!-- Could go wrong (e.g.: unclear semantics) if a property-attribute is also a project-attribute! -->
			<xsl:element name="ea:{local-name(.)}"><xsl:value-of select="."/></xsl:element>
		</xsl:for-each>
		<xsl:for-each select="tags/tag">
			<xsl:variable name="tagvalue"><xsl:value-of select="substring-before(concat(@value,'#NOTES#'),'#NOTES#')"/></xsl:variable>
			<xsl:if test="$tagvalue!=''">
				<uml:taggedValue>
					<uml:TaggedValue>
						<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
						<rdf:value><xsl:value-of select="$tagvalue"/></rdf:value>
					</uml:TaggedValue>
				</uml:taggedValue>
			</xsl:if>
		</xsl:for-each>
	</rdf:Description>
	<xsl:for-each select="attributes">
		<xsl:apply-templates select="attribute[exists(@xmi:idref)]" mode="extension"/>
	</xsl:for-each>
</xsl:template>

<xsl:template match="attribute" mode="extension">
	<rdf:Description rdf:about="{$domain}{@xmi:idref}">
		<xsl:if test="documentation/@value!=''">
			<ea:documentation><xsl:value-of select="documentation/@value"/></ea:documentation>
		</xsl:if>
		<xsl:for-each select="properties/@*">
			<xsl:element name="ea:{local-name(.)}"><xsl:value-of select="."/></xsl:element>
		</xsl:for-each>
		<xsl:for-each select="tags/tag">
			<xsl:variable name="tagvalue">
				<xsl:if test="exists(@value)">
					<xsl:choose>
						<xsl:when test="@value='&lt;memo&gt;'">
							<xsl:value-of select="@notes"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@value"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
				<!--
				<xsl:choose>
					<xsl:when test="exists(@notes) and @value='&lt;memo&gt;'">
						<xsl:value-of select="@notes"/>
					</xsl:when>
					<xsl:when test="exists(@notes) and not(@value='&lt;memo&gt;')">
						<xsl:value-of select="@value"/>
					</xsl:when>
					<xsl:otherwise>
						@@@NOTES@@@<xsl:value-of select="substring-before(@value,'#NOTES#')"/>
					</xsl:otherwise>
				</xsl:choose>
				-->
			</xsl:variable>
			<xsl:if test="$tagvalue!=''">
				<uml:taggedValue>
					<uml:TaggedValue>
						<rdfs:label><xsl:value-of select="@name"/></rdfs:label>
						<rdf:value><xsl:value-of select="$tagvalue"/></rdf:value>
					</uml:TaggedValue>
				</uml:taggedValue>
			</xsl:if>
		</xsl:for-each>
	</rdf:Description>
</xsl:template>

<xsl:template match="connector" mode="extension">
	<rdf:Description rdf:about="{$domain}{@xmi:idref}">
		<xsl:if test="documentation/@value!=''">
			<ea:documentation><xsl:value-of select="documentation/@value"/></ea:documentation>
		</xsl:if>
		<xsl:for-each select="properties/@*">
			<xsl:element name="ea:{local-name(.)}"><xsl:value-of select="."/></xsl:element>
		</xsl:for-each>
	</rdf:Description>
	<xsl:if test="source/documentation/@value!=''">
		<rdf:Description rdf:about="{$domain}{replace(@xmi:idref,'(EAID_..)','EAID_src')}"> <!-- Hack: ea uses src -->
			<ea:documentation><xsl:value-of select="source/documentation/@value"/></ea:documentation>
		</rdf:Description>
	</xsl:if>
	<xsl:if test="target/documentation/@value!=''">
		<rdf:Description rdf:about="{$domain}{replace(@xmi:idref,'(EAID_..)','EAID_dst')}"> <!-- Hack: ea uses dst -->
			<ea:documentation><xsl:value-of select="target/documentation/@value"/></ea:documentation>
		</rdf:Description>
	</xsl:if>
</xsl:template>

<xsl:template match="xmi:Extension[@extender='Enterprise Architect']">
	<xsl:for-each select="primitivetypes">
		<xsl:apply-templates select="*[exists(@xmi:type)]"/>
	</xsl:for-each>
	<xsl:for-each select="elements">
		<xsl:apply-templates select="element[exists(@xmi:idref)]" mode="extension"/>
	</xsl:for-each>
	<xsl:for-each select="connectors">
		<xsl:apply-templates select="connector[exists(@xmi:idref)]" mode="extension"/>
	</xsl:for-each>
</xsl:template>

<xsl:template match="/root">
	<rdf:RDF>
		<xsl:for-each select="xmi:XMI">
			<xsl:apply-templates select="*[exists(@xmi:type)]"/>
			<xsl:apply-templates select="*[exists(@base_Class)]"/>
			<xsl:apply-templates select="xmi:Extension"/>
		</xsl:for-each>
	</rdf:RDF>
</xsl:template>

<!--Catch all (debugmode) -->
<xsl:template match="*">
	<uml:Unexplored rdf:about="urn:Unexplored">
		<xsl:element name="uml:{local-name(.)}">Unexplored</xsl:element>
	</uml:Unexplored>
</xsl:template>
</xsl:stylesheet>