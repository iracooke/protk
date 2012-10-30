require 'rubygems'
require 'rexml/document'
require 'rexml/xpath'


class ProtXML 
    
  attr_accessor :groups
    
    
  def indistinguishable_proteins_from_protein(protein_element)
    iprots=[]
    REXML::XPath.each(protein_element,"./indistinguishable_protein") do |ipel|
      ipel_attributes={}
      ipel.attributes.each_attribute { |att| ipel_attributes[att.expanded_name.to_sym]=att.value }
      iprots.push(ipel_attributes[:protein_name])
    end    
    iprots
  end

  def peptides_from_protein(protein_element)
    peptides=[]
    REXML::XPath.each(protein_element,"./peptide") do |pel|
      peptide={}

      pel.attributes.each_attribute { |att| peptide[att.expanded_name.to_sym]=att.value }
      modifications=pel.get_elements("./modification_info")
      mods=modifications.collect {|mp| mp.attribute("modified_peptide").value }
      peptide[:modifications] = mods
      peptides.push(peptide)
    end
    peptides
  end
    
  def proteins_from_group(group_element)
    proteins=[]
    REXML::XPath.each(group_element,"./protein") do |pel|
      protein={}
      pel.attributes.each_attribute { |att| protein[att.expanded_name.to_sym]=att.value }
      protein[:peptides]=peptides_from_protein(pel)      
      protein[:indistinguishable_prots]=indistinguishable_proteins_from_protein(pel)
      proteins.push(protein)
    end
    proteins
  end
    
  def init_groups
    @groups=[]
    REXML::XPath.each(@doc.root,"//protein_group") do |gel|
      group={}
      group[:group_probability]=gel.attributes["probability"].to_f
      group[:proteins]=proteins_from_group(gel)
      groups.push group
    end
    @groups
  end


  def initialize(file_name)
    @doc=REXML::Document.new(File.new(file_name))
    @groups=self.init_groups
  end
  
  def peptide_sequences_from_protein(prot)
    peptides=prot[:peptides]
    sequences=[]
    peptides.each do |pep| 
      if ( pep[:modifications].length > 0 )
        pep[:modifications].each {|pmod| 
          sequences.push(pmod) }
      else
        sequences.push(pep[:peptide_sequence])
      end
    end
    sequences
  end
  
  def protein_to_row(prot)
    protein_row=[]
    protein_row.push(prot[:protein_name])
    protein_row.push(prot[:probability])
    
    indistinct=prot[:indistinguishable_prots]
    indist_string="#{prot[:protein_name]};"
    indistinct.each { |pr| indist_string<<"#{pr};"}
    indist_string.chop!
    protein_row.push(indist_string)
    
    protein_row.push(prot[:peptides].length)
    
    peptide_string=""
    peptide_sequences_from_protein(prot).each {|pep| peptide_string<<"#{pep};" }
    peptide_string.chop!
    
    protein_row.push(peptide_string)
    protein_row
  end
  
  # Convert the entire prot.xml document to row format
  # Returns an array of arrays. Each of the sub-arrays is a row.
  # Each row should contain a simple summary of the protein.
  # A separate row should be provided for every protein (including indistinguishable ones)
  # The first row will be the header
  # 
  # Proteins with probabilities below a threshold are excluded
  #
  def as_rows(threshold_probability)
    
    rows=[]
    rows.push(["Accession","Probability","Indistinguishable Proteins","Num Peptides","Peptides"])
    
    proteins=[]
    @groups.each do |grp|
      grp[:proteins].each {|prot| 
        if ( prot[:probability].to_f >= threshold_probability)
          proteins.push(prot)
        end
      }
    end
    
    proteins.each do |prot|
      protein_row=protein_to_row(prot)
      rows.push(protein_row)
      
      indistinguishables=prot[:indistinguishable_prots]
      indistinguishables.each do |indist|
        indist_row=protein_row.clone
        indist_row[0]=indist
        rows.push(indist_row)
      end
      
    end
    
    rows
  end
  
end