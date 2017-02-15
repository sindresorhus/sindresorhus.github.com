# Dev notes


## Generate the minified CSS

Comment out the `<link>` in `index.html` and uncomment the commented ones.

```
$ npm install --global uncss
```

```
$ uncss index.html --ignore=".nav-menu.is-active" >! main.min.css
```


## YQL for the latest blog post from RSS

```sql
select channel.item.title,channel.item.link from xml where url = 'https://blog.sindresorhus.com/feed' limit 1
```
