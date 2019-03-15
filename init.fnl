;
; A really simple HTTP parser and ring-like server for NodeMCU on the ESP32.
; This is free and unencumbered software released into the public domain.
;

; Coroutine stuff
(local create coroutine.create)
(local yield coroutine.yield)
(local resume coroutine.resume)

; Take an iterator over packets and return an iterator over lines
(fn line-iter [packets]
  (var buf "")
  (fn recur [] 
    (local (residual rest) (: buf :match "^([^\r\n]*)\r?\n(.*)$"))
    (if residual
      (do (set buf rest) residual)
      (let [packet (packets)]
        (set buf (.. buf packet))
        (recur)))))

; Takes an iterator over lines and returns an HTTP object.
(fn http-parse [lines]
  (let [head (lines)
        (method path version) (: head :match "^(%S+)%s+(%S+)%s+(%S+)$")
        headers {}
        req {:head head :uri path :method method :headers headers :protocol version}]
    (each [line lines]
      (if
        ; Parse body
        (= line "")
        (let [accum []]
          (when (or (= method :POST) (= method :PUT))
            (var body-line (lines))
            (while (and body-line (not= body-line ""))
              (table.insert accum body-line)
              (set body-line (lines)))
            (tset req :body (table.concat accum "\r\n")))
          (lua :break))
        ; Parse a header
        (let [(k v) (: line :match "^(%S+):%s*(.*)$")]
          (assert k)
          (tset headers (string.lower k) v))))
    req))

; Status codes - add whatever you need here.
(local status-codes
  {200 "OK"
   201 "Created"
   202 "Accepted"
   301 "Moved Permanently"
   302 "Found"
   400 "Bad Request"
   401 "Unauthorized"
   403 "Forbidden"
   404 "Not Found"
   500 "Internal Server Error"})

; Render a response object
(fn http-render
  [res]
  (let [buf []]
    (table.insert buf (.. "HTTP/1.1 " (tostring (or res.code 200)) " "
                          (or (. status-codes (or res.code 200)) "OK")))
    (when res.headers
      (each [h v (pairs res.headers)]
        (table.insert buf (.. (string.lower h) ": " v))))
    (when res.body
      (table.insert buf (.. "Content-Length: " (# res.body)))
      (table.insert buf "")
      (table.insert buf res.body))
    (table.insert buf "")
    (table.concat buf "\r\n")))

; Make an HTTP server
(fn serve [port handler]
  (let [srv (net.createServer net.TCP 30)
        coro-body (fn [conn]
                    (let [lines (line-iter yield)
                          req (http-parse lines)
                          close (fn [] (: conn :close))
                          res (handler req conn)
                          restext (http-render res)]
                      (print req.head (or res.code 200))
                      (: conn :send restext)))
        on-conn (fn [conn]
                  (let [coro (create coro-body)
                        close (fn [] (: conn :close))
                        recv (fn [_ data] (resume coro data))]
                    (resume coro conn)
                    (: conn :on :sent close)
                    (: conn :on :receive recv)))]
    (: srv :listen port on-conn)
    (print (.. "Listening on port " port "..."))))

; The module
(local ring {:lines line-iter
 :serve serve
 :http-parse http-parse})

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Setup wifi
(wifi.mode wifi.SOFTAP)
(wifi.ap.config
  {:ssid "MCU-serve"
   :pwd "12345678"
   :auto false})
(wifi.start)

; Server code
(fn handler [req]
  {:content-type "text/plain"
   :code 200
   :body "Hello from NodeMCU!"})

(ring.serve 80 handler)
