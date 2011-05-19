alias flushdns="dscacheutil -flushcache"

alias b='bundle exec'
alias fucking_eject='drutil tray eject'

alias sil='rvm use 1.8.7@silhouette'
alias deploy='heroku maintenance:on && git push heroku master && heroku rake db:migrate && heroku restart && heroku maintenance:off'

export EDITOR='mate -w'
export TEXEDIT='mate -w -l %d "%s"'
export LESSEDIT='mate -l %lm %f'

export PATH=$PATH:/opt/local/bin:/opt/usr/local/bin:/usr/local/mysql/bin:/opt/local/libexec/git-core:~/bin:/Users/anthony/.gem/ruby/1.8/bin:/Users/anthony/.local/bin:/Users/anthony/bin:/usr/local/mysql:/usr/local/sbin

export PS1='\[\033[0;35m\]\w $(git branch &>/dev/null; if [ $? -eq 0 ]; then echo "\[\033[0;36m\]$(git branch | grep '^*' |sed s/\*\ //)"; fi) \$ \[\033[00m\]'

alias pgstart='pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start'
alias pgstop='pg_ctl -D /usr/local/var/postgres stop -s -m fast'

# rvm
if [[ -s /Users/anthony/.rvm/scripts/rvm ]] ; then source /Users/anthony/.rvm/scripts/rvm ; fi

