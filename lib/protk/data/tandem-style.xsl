<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
                xmlns:GAML="http://www.bioml.com/gaml/" >
<!--
X! tandem default style sheet
Copyright (C) 2003-2004 Ronald C. Beavis
Version 2004.03.01
All Rights Reserved
     This source code is distributed under the terms of the
     Artistic License. 
-->
<xsl:template match="/">
  <html>
    <head>
      <title>thegpm site 000 <xsl:value-of select="/bioml/@label" /></title>
      <link rel="stylesheet" href="/tandem/tandem-style.css" />
 <SCRIPT lanuage="JavaScript">
 
function changeState(id)
{
	var block = document.getElementById(id);
	if(block.style.display == 'none')	{
		block.style.display = 'block';
	}
	else	{
		block.style.display = 'none';
	}
}
  </SCRIPT>
    </head>

    <body bgcolor="#FFFFFF">
	<TABLE bgcolor="#d0d0d0" CELLSPACING="2" CELLPADDING="2">
	<TR>
	<TD WIDTH="700" VALIGN="TOP" ALIGN="LEFT" class="top_note">X! tandem results</TD>
	</TR>
	<TR>
	<TD WIDTH="700" VALIGN="TOP" ALIGN="LEFT" class="top_note"><B><xsl:value-of select="/bioml/@label" /></B></TD>
	</TR>
	</TABLE>
	<BR></BR>
	<table border="1" bgcolor="#d0ffd0" cellpadding="2" cellspacing="2">
		<xsl:apply-templates select="/bioml/group" />
	</table>
     <xsl:if test="not(/bioml/group)">
 	<TABLE CELLSPACING="2" CELLPADDING="2">
	<TR>
	<TD WIDTH="700" VALIGN="TOP" ALIGN="LEFT">No models were provided.</TD>
	</TR>
	</TABLE>
   
     </xsl:if>
    </body>
  </html>
</xsl:template>

<xsl:template match="group">
	<xsl:if test="not(contains(@label,'parameters'))">
		<tr><td>
		<DIV onClick="changeState('{generate-id()}');" class="e" title="click to see/hide sequences and evidence">
					<SPAN CLASS="top_label">
			#<xsl:value-of select="@id" />, 
			e = <xsl:value-of select="@expect" />,
			M+H = <sup><xsl:value-of select="@z" /></sup><xsl:value-of select="@mh" />
			<sup><xsl:value-of select="./protein/peptide/domain/@delta" /></sup>,
			<SPAN class="aa_s"><xsl:value-of select="./protein/peptide/domain/@pre" /></SPAN>
			<SUP><xsl:value-of select="./protein/peptide/domain/@start" /></SUP>
			<SPAN class="aa_h"><xsl:value-of select="./protein/peptide/domain/@seq" /></SPAN>
			<SUP><xsl:value-of select="./protein/peptide/domain/@end" /></SUP>
			<SPAN class="aa_s"><xsl:value-of select="./protein/peptide/domain/@post" /></SPAN>,
			<xsl:for-each select="./protein[1]/peptide[1]/domain[1]/aa">
				
				<SUP><xsl:value-of select="@at" /></SUP><xsl:value-of select="@type" />(<xsl:value-of select="@modified" />),
				
			</xsl:for-each>
			</SPAN><BR></BR>
			<SPAN CLASS="top_note"> 
			<span class="b"> log(E) = <xsl:value-of select="./protein/@expect" /></span>,
			<xsl:value-of select="@label" />
			</SPAN>
			</DIV>

			<DIV id="{generate-id()}" STYLE="display:none" class="k">
			<TABLE border="1" bgcolor="#ffd0ff" CELLPADDING="1" CELLSPACING="1">
				<xsl:apply-templates select="protein" mode="sequence"/>
			</TABLE>
				<xsl:apply-templates select="group" mode="support"/>
			</DIV>
		</td></tr>
	</xsl:if>
	
	<xsl:if test="contains(@label,'parameters')">
		<DIV onClick="changeState('{generate-id()}');" title="click to see/hide values" class="e">
		<SPAN CLASS="top_label">+ <xsl:value-of select="@label" />
		</SPAN>
		</DIV>
		<DIV id="{generate-id()}" class="k" STYLE="display:none">
		<BR></BR>
		<TABLE border="0" bgcolor="#ffd0d0" CELLPADDING="1" CELLSPACING="1">
		<SPAN CLASS="top_note"><xsl:apply-templates select="note" />
		</SPAN>
		</TABLE>
		<HR></HR>
		</DIV>
	</xsl:if>
</xsl:template>

<xsl:template match="protein" mode="description">
		<BR></BR><SPAN CLASS="top_note"><B><xsl:value-of select="@id" /></B> : </SPAN><PRE><xsl:apply-templates select="note" /></PRE>
</xsl:template>

<xsl:template match="protein" mode="sequence">
		<tr><td>
		<DIV onClick="changeState('{generate-id()}');" title="click to see/hide details">
		<SPAN CLASS="top_label"><xsl:value-of select="@id" />: <xsl:value-of select="@label" />
		<xsl:apply-templates select="file" /></SPAN>
		</DIV>
		<DIV id="{generate-id()}" class="k" STYLE="display:none">
		<xsl:apply-templates select="peptide" />
		</DIV>
		</td></tr>
</xsl:template>

<xsl:template match="file">
		<SPAN class="top_label">(<xsl:value-of select="@URL" />)</SPAN>
</xsl:template>

<xsl:template match="aa">
		<SPAN class="top_note"><SUP><xsl:value-of select="@at" /></SUP><xsl:value-of select="@type" />(<xsl:value-of select="@modified" />),</SPAN>
</xsl:template>

<xsl:template match="GAML:attribute">
		<SPAN class="small_label"><xsl:value-of select="@type" /> = <xsl:value-of select="text()" />, </SPAN>
</xsl:template>

<xsl:template match="GAML:trace">

				<SPAN class="small_label">
				<B>
					<xsl:value-of select="@type" />
				</B>
				</SPAN>
			<TABLE BORDER="0" bgcolor="#ffffd0" CELLPADDING="1" CELLSPACING="1">
			<xsl:if test="GAML:attribute">
				<TR>
				<TD WIDTH="500" VALIGN="TOP" ALIGN="LEFT">
				parameters: <xsl:apply-templates select="GAML:attribute" />
				</TD>
				</TR>
			</xsl:if>
			<TR>
			<TD WIDTH="500" VALIGN="TOP" ALIGN="LEFT">
				x-values
			</TD>
			</TR>
			<TR>
			<TD WIDTH="500" VALIGN="TOP" ALIGN="LEFT">
				<xsl:value-of select="./GAML:Xdata/GAML:values/text()" />
			</TD>
			</TR>
			<TR>
			<TD WIDTH="500" VALIGN="TOP" ALIGN="LEFT">
				y-values
			</TD>
			</TR>
			<TR>
			<TD WIDTH="500" VALIGN="TOP" ALIGN="LEFT">
				<xsl:value-of select="./GAML:Ydata/GAML:values/text()" />
			</TD>
			</TR>
			</TABLE>
</xsl:template>

<xsl:template match="group" mode="support">
<xsl:if test="@type='support'">
	<DIV onClick="changeState('{generate-id()}');" class="e" title="click to see/hide evidence">
	<SPAN CLASS="top_label">
			<xsl:value-of select="@label" />
	</SPAN></DIV>
	<DIV id="{generate-id()}" STYLE="display:none" class="k">
		<xsl:apply-templates select="GAML:trace" />
	</DIV>
	</xsl:if>
</xsl:template>



<xsl:template match="peptide">
		<xsl:apply-templates select="domain" />
	<DIV onClick="changeState('{generate-id()}');" class="e" title="click to see/hide sequence">
				<SPAN class="top_label">
					log(e) = <xsl:value-of select="./../@expect" />,
					<xsl:value-of select="./../@label" />
				</SPAN>
	</DIV>
	<DIV id="{generate-id()}" STYLE="display:none">
		<TABLE BORDER="0" gbcolor="#d0d0ff">
			<TR>
				<TD WIDTH="500" ALIGN="LEFT" VALIGN="TOP" CLASS="residues"><xsl:value-of select="text()" />
				</TD>
			</TR>
		</TABLE>
	</DIV>
</xsl:template>

<xsl:template match="domain">
		<SPAN CLASS="top_note">
		<B><xsl:value-of select="@id" /></B>: 
		e = <xsl:value-of select="@expect" />,
		<SUP><xsl:value-of select="@start" /></SUP><SPAN class="aa_h"><xsl:value-of select="@seq" /></SPAN><SUP><xsl:value-of select="@end" /></SUP>,
		<xsl:apply-templates select="aa"/><BR></BR>
		M+H = <xsl:value-of select="@mh" /> Da,
		<SPAN CLASS="greek">d</SPAN> = <xsl:value-of select="@delta" />,
		!score = <xsl:value-of select="@hyperscore" />,
		y/b: scores = <xsl:value-of select="@y_score" />/<xsl:value-of select="@b_score" />,
		ions = <xsl:value-of select="@y_ions" />/<xsl:value-of select="@b_ions" />
		</SPAN>
		<BR></BR>
</xsl:template>

<xsl:template match="note">
	<xsl:if test="not(contains(@label,'description'))">
	<TR>
		<TD WIDTH="350" ALIGN="RIGHT"><xsl:value-of select="@label" /> = </TD>
		<TD WIDTH="350" ALIGN="LEFT"><xsl:value-of select="text()" /></TD>
	</TR>
	</xsl:if>
	<xsl:if test="contains(@label,'description')">
		<SPAN CLASS="top_note">
		<xsl:choose>
			<xsl:when test="contains(self::note,'ENSMUSP')">
				<a target="_BLANK">
				<xsl:attribute name="href">http://www.ensembl.org/Mus_musculus/protview?peptide=<xsl:value-of select="text()"/></xsl:attribute>
				<xsl:attribute name="title">View Ensembl Protein Report</xsl:attribute>
				<span class="ensembl"><xsl:value-of select="text()" /></span>
				</a>
			</xsl:when>
			<xsl:when test="contains(self::note,'ENSRNOP')">
				<a target="_BLANK">
				<xsl:attribute name="href">http://www.ensembl.org/Rattus_norvegicus/protview?peptide=<xsl:value-of select="text()"/></xsl:attribute>
				<xsl:attribute name="title">View Ensembl Protein Report</xsl:attribute>
				<span class="ensembl"><xsl:value-of select="text()" /></span>
				</a>
			</xsl:when>
			<xsl:when test="contains(self::note,'ENSP')">
				<a target="_BLANK">
				<xsl:attribute name="href">http://www.ensembl.org/Homo_sapiens/protview?peptide=<xsl:value-of select="text()"/></xsl:attribute>
				<xsl:attribute name="title">View Ensembl Protein Report</xsl:attribute>
				<span class="ensembl"><xsl:value-of select="text()" /></span>
				</a>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="text()" />
			</xsl:otherwise>
		</xsl:choose>
		</SPAN>
	</xsl:if>
</xsl:template>



</xsl:stylesheet>

