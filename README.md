# MCU-serve

A very bareones HTTP server on the ESP32 with NodeMCU and [Fennel](https://fennel-lang.org)
Can be used as a starting point for building a standalone, IoT
web server with Fennel. Made for [FennelConf 2019](https://conf.fennel-lang.org/2019)

## Tools

The Makefile uses the [nodemcu-uploader](https://github.com/kmpm/nodemcu-uploader) to upload code
to the ESP32. It has also been tested to work with [NodeMUC-tool](https://www.npmjs.com/package/nodemcu-tool)
a similar utility written with Node.js rather than python.

You will also need the latest [Fennel](https://fennel-lang.org) compiler to build, at least a version recent enough to correctly
compile `(lua :break)`.
