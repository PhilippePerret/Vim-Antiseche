#!/usr/bin/env ruby
# encoding: UTF-8
=begin

Je suis à la page 83 du fichier VIM.pdf

=end

require 'yaml'

SHORTCUTS = YAML.load_file('./01_Mon_Aide_Rapide.yml')

# # Décommenter les lignes ci-dessous si l'on veut juste voir
# # les données ou voir si elles sont valides.
# puts SHORTCUTS
# exit

# On va faire aussi une table des matières horizontale pour atteindre les
# éléments plus vite.


class String
  def titleize
    str = "#{self}".downcase
    str = str.tr('ÊÉÈ','êéè')
    str[0] = str[0].upcase
    return str
  end
end

COLUMN4_WIDTH = 100
COLUMN0_WIDTH = 160
COLUMN1_WIDTH = 480
COLUMN2_WIDTH = 490
COLUMN3_WIDTH = 280



entete =
  <<-HTML
  <tr>
    <th width="#{COLUMN4_WIDTH}">Tags</th>
    <th width="#{COLUMN0_WIDTH}">Action</th>
    <th width="#{COLUMN1_WIDTH}"><!-- Sous-action --></th>
    <th width="#{COLUMN2_WIDTH}">Shortcut</th>
    <th width="#{COLUMN3_WIDTH}">Mnémo</th>
  </tr>
  HTML

num_tdm = 0
tdm = ''
data_tdm = {}

def keyboard image
  "<img src=\"./img/clavier/K_#{image}.png\" class=\"kb\" title=\"#{image}\"/>"
end
def formate t
  t != nil || (return '')
  t.to_s
  .gsub(/<(\/?)sel>/,'__\1SELECTION__')
  .gsub(/</,'&lt;')
  .gsub(/\(\((.*?)\)\)/,'<memo>\1</memo>')
  .gsub(/(\[(?:NORMAL|INSERT|VISUAL|VISUEL)\])/, '<mode>\1</mode>')
  .gsub(/\bALT\b ?/, keyboard('Alt'))
  .gsub(/\bCMD\b ?/, keyboard('Command'))
  .gsub(/\bSPACE\b/, keyboard('Espace'))
  .gsub(/\bCTRL\b ?/, keyboard('Control'))
  .gsub(/\bESC\b ?/, keyboard('Escape'))
  .gsub(/\bMAJ\b ?/, keyboard('Maj'))
  .gsub(/\bTAB\b ?/, keyboard('Tab'))
  .gsub(/ ?\bENTER\b/, keyboard('Entree'))
  .gsub(/\bARROW_UP\b/, keyboard('FlecheH'))
  .gsub(/\bARROW_DOWN\b/, keyboard('FlecheB'))
  .gsub(/Key(Arobase|CrochetO|CrochetF|Diese|Dollar|FlecheG|FlecheD|FlecheH|FlecheB|Egal|Etoile|Interro|Livre|Point_virgule|Point|SupInf|Tab|Virgule) ?/){keyboard($1)}
  .gsub(/Key([A-Z]) ?/){keyboard($1.upcase)}
  .gsub(/\`\`\`(.*?)\`\`\`/m){
    c = $1.gsub(/\\n/, "[RC]").strip
    "<pre><code>#{c}</code></pre>"
  }
  .gsub(/\`(.*?)\`/m,'<code>\1</code>')
  .gsub(/\n/,'<br>')
  .gsub(/__(\/?)SELECTION__/,'<\1sel>')
  .gsub(/\[RC\]/,"\n")
end
def tag mot
  "<span class='tag'>#{mot.split('_').join(' ')}</span>"
end

table = ''
ishortcut = 0

SHORTCUTS.each do |element_titre, data_element|
  num_tdm += 1
  data_tdm.merge!("titre#{num_tdm}" => element_titre)
  tdm << "<li><a href='#titre#{num_tdm}'>#{element_titre.titleize}</a></li>"

  table <<  "<h3 id='titre#{num_tdm}'>#{element_titre}</h3>"
  table << '<table cellspacing="0" cellpadding="0">' + entete

  data_element.each do |data_sc|
  # data_element.each do |action, data_sc|

    ishortcut += 1
    # data_sc contient :
    # -------------
    #   :main_action (if any)
    #   :action       La sous-action
    #   :mode         Le mode VIM (normal/Normal/NORMAL, visual, insert)
    #   :code         Ce qu'il faut jouer
    #                 Peut-être un simple texte ou une liste de possibilités
    #   :memo         Le repère mnémotechnique
    #   :exemples     Une liste éventuelle d'exemples. Ils sont mis dans
    #                 une rangée supplémentaire qui se rétracte
    #   :note         Une note
    #   :notes        Une liste de notes
    #   :tags         les tags du raccourci

    tags = data_sc[:tags]
    if tags
      tags = tags.split(' ').collect{|tg| tag(tg)}.join('')
    end

    # Le code
    code = data_sc[:code]
    code.is_a?(Array) || code = [code]
    code = code.collect do |c|
      if data_sc[:mode]
        "<mode>[#{data_sc[:mode].upcase}]</mode> #{formate(c)}"
      else
        formate(c)
      end
    end.join('<br>')

    # Est-ce que c'est une rangée importante ?
    is_importante = !!data_sc[:important]

    main_tr_class = is_importante ? ' class="main"' : ''

    # Pour savoir s'il y a un repère mnémotechnique. S'il n'y en a
    # pas, on allonge la taille de la cellule contenant le code, les
    # valeurs et les exemples.
    no_memo = data_sc[:memo] == nil

    cellule_memo = no_memo ? '' : "<td>#{formate(data_sc[:memo])}</td>"
    # On construit la rangée principale
    rangee =
      <<-HTML
      <tr#{main_tr_class}>
        <td>#{tags}</td>
        <td class='mainaction' colspan='2'>#{formate(data_sc[:main_action])} #{formate(data_sc[:action])}</td>
        <td colspan="#{no_memo ? '2' : '1'}" class="shortcut">#{code}</td>
        #{cellule_memo}
      </tr>
      HTML

    # S'il y a des valeurs
    if data_sc[:values]
      values =
        data_sc[:values].collect do |param, values|
          "  avec `#{param}` :\n" + values.collect { |val| "    #{val}" }.join("\n")
        end.join("\n")
      rangee += <<-HTML
      <tr class='values'>
        <td colspan='2'></td>
        <td class='titre'>Valeurs</td>
        <td colspan="#{no_memo ? '2' : '1'}" class='values'>#{formate(values)}</td>
        #{no_memo ? '' : '<td></td>'}
      </tr>
      HTML
    end

    # S'il y a une note, on l'ajoute sous la ligne
    if data_sc[:note] || data_sc[:notes]
      data_sc[:notes].is_a?(String) && data_sc[:notes] = [data_sc[:notes]]
      data_sc[:notes] ||= Array.new
      data_sc[:note] && data_sc[:notes] << data_sc[:note]
      nombre_notes = data_sc[:notes].count
      data_sc[:notes].each_with_index do |note, index|
        rangee += <<-HTML
        <tr class="notes">
          <td colspan="2"></td>
          <td class="titre">#{nombre_notes > 1 ? "Note #{index + 1}" : 'Note'}</td>
          <td colspan="2">#{formate(note)}</td>
        </tr>
        HTML
      end
    end

    # S'il y a des exemples, on les ajoute dans une rangée en dessous.
    if data_sc[:exemples]
      exemples = data_sc[:exemples]
      exemples.is_a?(Array) || exemples = [exemples]
      nombre_exemples = exemples.count
      exemples = exemples.collect do |exemple|
        "<div class=\"exemple\">#{formate(exemple)}</div>"
      end.join('')
      rangee += <<-HTML
      <tr class="exemples">
        <td colspan="2"></td>
        <td class="titre"><em>Exemple#{nombre_exemples > 1 ? 's' : ''}</em></td>
        <td colspan="2">#{exemples}</td>
      </tr>
      HTML
    end

    table << rangee
  end
  table << '</table>'
end


# Finaliser la table des matières
tdm = <<-HTML
<ul id="tdm">#{tdm}</ul>
HTML

table = <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Vim - Antisèche</title>
    <style media="screen">
      body{font-size:17pt;padding:2em;margin:0;margin-top:8em;padding:0}
      header{position:fixed;top:0;background-color:white;margin:0;z-index:100;}
      header a, header a:link, header a:visited, header a:hover {color:blue;}
      header h1{margin:0;padding:12px 24px;font-weight:none;font-size:23pt;}
      section#table_shortcuts{margin:9em 2em;z-index:1;}
      td.shortcut{font-family:Courier;font-size:0.72em;background-color:#333!important;color:white!important;padding:4px}
      table tr.values td.values{white-space:pre-wrap;font-size:11pt;font-family:Courier;background-color:#CCC!important;}
      table tr.main td{border-top:2px solid green;border-bottom:2px solid green;background-color:#EFE;}
      table tr td{border-width:2px 0;border-style:solid;border-color:white;}
      table tr:hover{background-color:#EEF;}
      table tr:hover td{border-color:red;}
      table tr th{text-align:left;font-style:italic;color:#777;font-weight:normal;}
      table tr td{vertical-align:top;}
      table tr.notes{opacity:0.3;}
      table tr.notes:hover{opacity:1;}
      table tr.notes td{font-size:0.9em;font-style:italic;}
      table tr.notes td.titre{text-align:right;padding-right:2em;}
      table tr.exemples{font-size:0.85em;opacity:0.3}
      table tr.exemples:hover{opacity:1}
      table td.titre{font-style:italic;text-align:right;padding-right:2em;}
      /*table tr.exemples td.titre{font-style:italic;text-align:right;padding-right:2em;}*/
      td.mainaction, td.action{font-family:Arial,Helvetica;font-size:0.9em;}
      td.mainaction{text-align:left;padding-right:0.5em;}
      td.action{font-weight: normal;}
      span.tag{color:#999;border:1px solid;border-radius:4px;padding:0px 4px;font-family:Avenir;font-size:10pt;}
      img{vertical-align:middle;}
      img.kb{margin-right:4px;}
      memo, shortcut {color: #009;font-size:inherit;font-family:'Courier New';}
      memo{margin-right:3px;}
      memo:before{content:'<';font-size:8pt;vertical-align:middle;}
      memo:after{content:'>';font-size:8pt;vertical-align:middle;}
      mode{color:#AAA;font-size:0.8em;font-weight:normal;}
      ul#tdm{list-style:none;margin:1em 0}
      ul#tdm li{margin:0;margin-right:1em;padding:0;display:inline;}
      ul#tdm li a{font-family:Arial;font-size:12pt;}
      p.explication{font-color:#555;opacity:0.5;font-style:italic;font-size:0.75em;}
      p.explication:hover{opacity:1;}
      pre{background-color:#333;padding:.5em}
      code{background-color:#333;color:white;padding:0 4px;}
      sel{background-color:#550;color:white;padding:0 1px;}
    </style>
  </head>
  <body>
    <header>
      <h1>Vim - Antisèche</h1>
      #{tdm}
    </header>
    <section id="table_shortcuts">
      #{table}
    </section>
  </body>
</html>
HTML

destfile = './03_Mon_Aide_Rapide.html'
File.open(destfile,'w'){|f|f.write table}

`open "#{destfile}"`
