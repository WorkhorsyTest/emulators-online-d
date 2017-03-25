# emulators-online
HTML based front end for video game console emulators

http://emulators-online.com

It uses WebSockets to connect the HTML front-end, to a D back-end. The
back-end manages the emulators and game files.


Checkout the code
-----
~~~bash
git clone http://github.com/workhorsy/emulators-online-d
cd emulators-online-d
git clone http://github.com/workhorsy/images_nintendo images/Nintendo
git clone http://github.com/workhorsy/images_sega images/Sega
git clone http://github.com/workhorsy/images_sony images/Sony
~~~


Build and run the exe
-----
~~~bash
./make.sh 9090
~~~

Visit this url
~~~bash
http://localhost:9090
~~~
