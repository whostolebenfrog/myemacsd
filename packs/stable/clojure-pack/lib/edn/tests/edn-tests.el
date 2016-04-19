(require 'ert)
(require 'edn)

(ert-deftest whitespace ()
  :tags '(edn)
  (should (null (edn-read "")))
  (should (null (edn-read " ")))
  (should (null (edn-read "   ")))
  (should (null (edn-read "	")))
  (should (null (edn-read "		")))
  (should (null (edn-read ",")))
  (should (null (edn-read ",,,,")))
  (should (null (edn-read "	  , ,
")))
  (should (null (edn-read"
  ,, 	")))
  (should (equal [a b c d] (edn-read "[a ,,,,,, b,,,,,c ,d]"))))

(ert-deftest symbols ()
  :tags '(edn symbol)
  (should (equal 'foo (edn-read "foo")))
  (should (equal 'foo\. (edn-read "foo.")))
  (should (equal '%foo\. (edn-read "%foo.")))
  (should (equal 'foo/bar (edn-read "foo/bar")))
  (equal 'some\#sort\#of\#symbol (edn-read "some#sort#of#symbol"))
  (equal 'truefalse (edn-read "truefalse"))
  (equal 'true. (edn-read "true."))
  (equal '/ (edn-read "/"))
  (should (equal '.true (edn-read ".true")))
  (should (equal 'some:sort:of:symbol (edn-read "some:sort:of:symbol")))
  (equal 'foo-bar (edn-read "foo-bar"))
  (should (equal '+some-symbol (edn-read "+some-symbol")))
  (should (equal '-symbol (edn-read "-symbol"))))

(ert-deftest booleans ()
  :tags '(edn boolean)
  (should (equal t (edn-read "true")))
  (should (equal nil (edn-read "false "))))

(ert-deftest characters ()
  :tags '(edn characters)
  (should (equal 97 (edn-read "\\a")))
  (should (equal 960 (edn-read "\\u03C0")))
  (should (equal 'newline (edn-read "\\newline"))))

(ert-deftest elision ()
  :tags '(edn elision)
  (should-not (edn-read "#_foo"))
  (should-not (edn-read "#_ 123"))
  (should-not (edn-read "#_:foo"))
  (should-not (edn-read "#_ \\a"))
  (should-not (edn-read "#_
\"foo\""))
  (should-not (edn-read "#_ (1 2 3)"))
  (should (equal '(1 3) (edn-read "(1 #_ 2 3)")))
  (should (equal '[1 2 3 4] (edn-read "[1 2 #_[4 5 6] 3 4]")))
  (should (map-equal (make-seeded-hash-table :foo :bar)
                     (edn-read "{:foo #_elided :bar}")))
  (should (equal (edn-list-to-set '(1 2 3 4))
                 (edn-read "#{1 2 #_[1 2 3] 3 #_ (1 2) 4}")))
  (should (equal [a d] (edn-read "[a #_ ;we are discarding what comes next
 c d]"))))

(ert-deftest string ()
  :tags '(edn string)
  (should (equal "this is a string" (edn-read "\"this is a string\"")))
  (should (equal "this has an escaped \"quote in it"
                 (edn-read "\"this has an escaped \\\"quote in it\"")))
  (should (equal "foo\tbar" (edn-read "\"foo\\tbar\"")))
  (should (equal "foo\nbar" (edn-read "\"foo\\nbar\"")))
  (should (equal "this is a string \\ that has an escaped backslash"
                 (edn-read "\"this is a string \\\\ that has an escaped backslash\"")))
  (should (equal "[" (edn-read "\"[\""))))

(ert-deftest keywords ()
  :tags '(edn keywords)
  (should (equal :namespace\.of\.some\.length/keyword-name
                 (edn-read ":namespace.of.some.length/keyword-name")))
  (should (equal :\#/\# (edn-read ":#/#")))
  (should (equal :\#/:a (edn-read ":#/:a")))
  (should (equal :\#foo (edn-read ":#foo"))))

(ert-deftest integers ()
  :tags '(edn integers)
  (should (= 0 (edn-read "0")))
  (should (= 0 (edn-read "+0")))
  (should (= 0 (edn-read "-0")))
  (should (= 100 (edn-read "100")))
  (should (= -100 (edn-read "-100"))))

(ert-deftest floats ()
  :tags '(edn floats)
  (should (= 12.32 (edn-read "12.32")))
  (should (= -12.32 (edn-read "-12.32")))
  (should (= 9923.23 (edn-read "+9923.23")))
  (should (= 4.5e+044 (edn-read "45e+43")))
  (should (= -4.5e-042 (edn-read "-45e-43")))
  (should (= 4.5e+044 (edn-read "45E+43"))))

(ert-deftest lists ()
  :tags '(edn lists)
  (should-not (edn-read "()"))
  (should (equal '(1 2 3) (edn-read "( 1 2 3)")))
  (should (equal '(12.1 ?a foo :bar) (edn-read "(12.1 \\a foo :bar)")))
  (should (equal '((:foo bar :bar 12)) (edn-read "( (:foo bar :bar 12))")))
  (should (equal
           '(defproject com\.thortech/data\.edn "0.1.0-SNAPSHOT")
           (edn-read "(defproject com.thortech/data.edn \"0.1.0-SNAPSHOT\")"))))

(ert-deftest vectors ()
  :tags '(edn vectors)
  (should (equal [] (edn-read "[]")))
  (should (equal [] (edn-read "[ ]")))
  (should (equal '[1 2 3] (edn-read "[ 1 2 3 ]")))
  (should (equal '[12.1 ?a foo :bar] (edn-read "[ 12.1 \\a foo :bar]")))
  (should (equal '[[:foo bar :bar 12]] (edn-read "[[:foo bar :bar 12]]")))
  (should (equal '[( :foo bar :bar 12 ) "foo"]
                 (edn-read "[(:foo bar :bar 12) \"foo\"]")))
  (should (equal '[/ \. * ! _ \? $ % & = - +]
                 (edn-read "[/ . * ! _ ? $ % & = - +]")))
  (should (equal [99 newline return space tab]
                 (edn-read "[\\c \\newline \\return \\space \\tab]"))))

(defun map-equal (m1 m2)
  (and (and (hash-table-p m1) (hash-table-p m2))
       (eq (hash-table-test m1) (hash-table-test m2))
       (= (hash-table-count m1) (hash-table-count m2))
       (equal (hash-table-keys m1) (hash-table-keys m2))
       (equal (hash-table-values m1) (hash-table-values m2))))

(defun make-seeded-hash-table (&rest keys-and-values)
  (let ((m (make-hash-table :test #'equal))
        (kv-pairs (-partition 2 keys-and-values)))
    (dolist (pair kv-pairs)
      (puthash (car pair) (cadr pair) m))
    m))

(ert-deftest maps ()
  :tags '(edn maps)
  (should (hash-table-p (edn-read "{ }")))
  (should (hash-table-p (edn-read "{}")))
  (should (map-equal (make-seeded-hash-table :foo :bar :baz :qux)
                     (edn-read "{ :foo :bar :baz :qux}")))
  (should (map-equal (make-seeded-hash-table 1 "123" 'vector [1 2 3])
                     (edn-read "{ 1 \"123\" vector [1 2 3]}")))
  (should (map-equal (make-seeded-hash-table [1 2 3] "some numbers")
                     (edn-read "{[1 2 3] \"some numbers\"}"))))

(ert-deftest sets ()
  :tags '(edn sets)
  (should (edn-set-p (edn-read "#{}")))
  (should (edn-set-p (edn-read "#{ }")))
  (should (equal (edn-list-to-set '(1 2 3)) (edn-read "#{1 2 3}")))
  (should (equal (edn-list-to-set '(1 [1 2 3] 3)) (edn-read "#{1 [1 2 3] 3}"))))

(ert-deftest comment ()
  :tags '(edn comments)
  (should-not (edn-read ";nada"))
  (should (equal 1 (edn-read ";; comment
1")))
  (should (equal [1 2 3] (edn-read "[1 2 ;comment to eol
3]")))
  (should (equal '[valid more items] (edn-read "[valid;touching trailing comment
 more items]")))
  (should (equal [valid vector more vector items] (edn-read "[valid vector
 ;;comment in vector
 more vector items]"))))

(defun test-val-passed-to-handler (val)
  (should (listp val))
  (should (= (length val) 2))
  (should (= 1 (car val)))
  1)

(edn-add-reader "my/type" #'test-val-passed-to-handler)
(edn-add-reader :my/other-type (lambda (val) 2))

(ert-deftest tags ()
  :tags '(edn tags)
  (should-error (edn-read "#my/type value"))
  (should (= 1 (edn-read "#my/type (1 2)")))
  (should (= 2 (edn-read "#my/other-type {:foo :bar}"))))

(ert-deftest roundtrip ()
  :tags '(edn roundtrip)
  (let ((data [1 2 3 :foo (4 5) qux "quux"]))
    (should (equal data (edn-read (edn-print-string data))))
    (should (map-equal (make-seeded-hash-table :foo :bar)
                       (edn-read (edn-print-string (make-seeded-hash-table :foo :bar)))))
    (should (equal (edn-list-to-set '(1 2 3 [3 1.11]))
                   (edn-read (edn-print-string (edn-list-to-set '(1 2 3 [3 1.11]))))))
    (should-error (edn-read "#myapp/Person {:first \"Fred\" :last \"Mertz\"}"))))

(ert-deftest inst ()
  :tags '(edn inst)
  (let* ((inst-str "#inst \"1985-04-12T23:20:50.52Z\"")
         (inst (edn-read inst-str))
         (time (date-to-time "1985-04-12T23:20:50.52Z")))
    (should (edn-inst-p inst))
    (should (equal time (edn-inst-to-time inst)))
    (should (equal inst-str (edn-print-string inst)))))

(ert-deftest uuid ()
  :tags '(edn uuid)
  (let* ((str "f81d4fae-7dec-11d0-a765-00a0c91e6bf6")
         (uuid (edn-read (concat "#uuid \"" str "\""))))
    (should (edn-uuid-p uuid))
    (should (equal str (edn-uuid-to-string uuid)))))

(ert-deftest invalid-edn ()
  (should-error (edn-read "///"))
  (should-error (edn-read "~cat"))
  (should-error (edn-read "foo/bar/baz/qux/quux"))
  (should-error (edn-read "#foo/"))
  (should-error (edn-read "foo/"))
  (should-error (edn-read ":foo/"))
  (should-error (edn-read "#/foo"))
  (should-error (edn-read "/symbol"))
  (should-error (edn-read ":/foo"))
  (should-error (edn-read "+5symbol"))
  (should-error (edn-read ".\\newline"))
  (should-error (edn-read "0cat"))
  (should-error (edn-read "-4cats"))
  (should-error (edn-read ".9"))
  (should-error (edn-read ":keyword/with/too/many/slashes"))
  (should-error (edn-read ":a.b.c/"))
  (should-error (edn-read "\\itstoolong"))
  (should-error (edn-read ":#/:"))
  (should-error (edn-read "/foo//"))
  (should-error (edn-read "///foo"))
  (should-error (edn-read ":{}"))
  (should-error (edn-read "//"))
  (should-error (edn-read "##"))
  (should-error (edn-read "::"))
  (should-error (edn-read "::a"))
  (should-error (edn-read ".5symbol"))
  (should-error (edn-read "{ \"foo\""))
  (should-error (edn-read "{ \"foo\" :bar"))
  (should-error (edn-read "{"))
  (should-error (edn-read ":{"))
  (should-error (edn-read "{{"))
  (should-error (edn-read "}"))
  (should-error (edn-read ":}"))
  (should-error (edn-read "}}"))
  (should-error (edn-read "#:foo"))
  (should-error (edn-read "\\newline."))
  (should-error (edn-read "\\newline0.1"))
  (should-error (edn-read "^"))
  (should-error (edn-read ":^"))
  (should-error (edn-read "_:^"))
  (should-error (edn-read "#{{[}}"))
  (should-error (edn-read "[}"))
  (should-error (edn-read "@cat")))
