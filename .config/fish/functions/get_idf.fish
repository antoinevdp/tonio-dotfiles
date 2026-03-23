function get_idf --wraps='. $HOME/esp/esp-idf/export.sh' --wraps='. $HOME/esp/esp-idf/export.fish' --description 'alias get_idf=. $HOME/esp/esp-idf/export.fish'
  . $HOME/esp/esp-idf/export.fish $argv
        
end
