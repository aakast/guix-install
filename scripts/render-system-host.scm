(use-modules (ice-9 format)
             (ice-9 rdelim)
             (ice-9 regex)
             (srfi srfi-1)
             (system service-sets registry))

(define (usage)
  (format (current-error-port)
          "Usage: guile -L <repo-root> render-system-host.scm <template> <definition> <out> <esp-uuid> <boot-uuid> <luks-swap-uuid> <luks-root-uuid>~%")
  (exit 1))

(define args (cdr (command-line)))

(when (not (= (length args) 7))
  (usage))

(define template-path (list-ref args 0))
(define definition-path (list-ref args 1))
(define out-path (list-ref args 2))
(define esp-uuid (list-ref args 3))
(define boot-uuid (list-ref args 4))
(define luks-swap-uuid (list-ref args 5))
(define luks-root-uuid (list-ref args 6))

(define (slurp path)
  (call-with-input-file path
    (lambda (port)
      (let loop ((chunks '()))
        (let ((chunk (read-string port 8192)))
          (if (or (eof-object? chunk)
                  (string-null? chunk))
              (apply string-append (reverse chunks))
              (loop (cons chunk chunks))))))))

(define (write-file path content)
  (call-with-output-file path
    (lambda (port)
      (display content port))))

(define (object->rendered-string obj)
  (call-with-output-string
    (lambda (port)
      (write obj port))))

(define (object->quoted-expression obj)
  (object->rendered-string `(quote ,obj)))

(define (as-string value)
  (if (string? value)
      value
      (error "Expected string value" value)))

(define (as-list value)
  (if (list? value)
      value
      (error "Expected list value" value)))

(define (alist-ref-required key alist)
  (let ((pair (assoc key alist)))
    (if pair
        (cdr pair)
        (error "Missing required key in host definition" key))))

(define (placeholder token)
  (string-append "{{" token "}}"))

(define (string-replace-all haystack needle replacement)
  (regexp-substitute/global #f
                            (make-regexp (regexp-quote needle))
                            haystack
                            'pre
                            replacement
                            'post))

(define (replace-placeholders template replacements)
  (fold (lambda (entry content)
          (string-replace-all content (car entry) (cdr entry)))
        template
        replacements))

(define (join-module-forms modules)
  (if (null? modules)
      ""
      (string-append
       "\n "
       (string-join (map object->rendered-string modules) "\n "))))

(define (append-expression symbols)
  (if (null? symbols)
      "'()"
      (string-append "(append "
                     (string-join (map symbol->string symbols) " ")
                     ")")))

(load definition-path)

(when (not (defined? '%host-definition))
  (error "Host definition file must define %host-definition" definition-path))

(define host-definition %host-definition)
(define primary-user (alist-ref-required 'primary-user host-definition))
(define service-set-names (as-list (alist-ref-required 'service-sets host-definition)))
(define resolved-sets (map resolve-service-set service-set-names))

(define service-set-modules
  (map (lambda (set) (alist-ref-required 'module set)) resolved-sets))

(define service-set-services-vars
  (map (lambda (set) (alist-ref-required 'services-variable set)) resolved-sets))

(define service-set-packages-vars
  (map (lambda (set) (alist-ref-required 'packages-variable set)) resolved-sets))

(define service-set-kernel-args-vars
  (map (lambda (set) (alist-ref-required 'kernel-arguments-variable set)) resolved-sets))

(define host-name (as-string (alist-ref-required 'host-name host-definition)))
(define managed-dirs (as-list (alist-ref-required 'managed-directories host-definition)))
(define kernel-arguments (as-list (alist-ref-required 'kernel-arguments host-definition)))

(define rendered
  (replace-placeholders
   (slurp template-path)
   (list
    (cons (placeholder "ESP_UUID") esp-uuid)
    (cons (placeholder "BOOT_UUID") boot-uuid)
    (cons (placeholder "LUKS_SWAP_UUID") luks-swap-uuid)
    (cons (placeholder "LUKS_ROOT_UUID") luks-root-uuid)
    (cons (placeholder "SERVICE_SET_MODULES") (join-module-forms service-set-modules))
    (cons (placeholder "DIRECTORY_BOOTSTRAP_SERVICE_NAME")
          (string-append "'create-" host-name "-directories"))
    (cons (placeholder "MANAGED_DIRECTORIES")
          (object->quoted-expression managed-dirs))
    (cons (placeholder "HOST_NAME")
          (object->rendered-string host-name))
    (cons (placeholder "TIMEZONE")
          (object->rendered-string (as-string (alist-ref-required 'timezone host-definition))))
    (cons (placeholder "LOCALE")
          (object->rendered-string (as-string (alist-ref-required 'locale host-definition))))
    (cons (placeholder "LOCALE_SOURCE")
          (object->rendered-string (as-string (alist-ref-required 'locale-source host-definition))))
    (cons (placeholder "HOST_KERNEL_ARGUMENTS")
          (object->quoted-expression kernel-arguments))
    (cons (placeholder "PRIMARY_USER_NAME")
          (object->rendered-string (as-string (alist-ref-required 'name primary-user))))
    (cons (placeholder "PRIMARY_USER_COMMENT")
          (object->rendered-string (as-string (alist-ref-required 'comment primary-user))))
    (cons (placeholder "PRIMARY_USER_GROUP")
          (object->rendered-string (as-string (alist-ref-required 'group primary-user))))
    (cons (placeholder "PRIMARY_USER_HOME")
          (object->rendered-string (as-string (alist-ref-required 'home-directory primary-user))))
    (cons (placeholder "PRIMARY_USER_SUPPLEMENTARY_GROUPS")
          (object->quoted-expression (as-list (alist-ref-required 'supplementary-groups primary-user))))
    (cons (placeholder "SERVICE_SET_SERVICES_EXPR")
          (append-expression service-set-services-vars))
    (cons (placeholder "SERVICE_SET_PACKAGES_EXPR")
          (append-expression service-set-packages-vars))
    (cons (placeholder "SERVICE_SET_KERNEL_ARGUMENTS_EXPR")
          (append-expression service-set-kernel-args-vars)))))

(write-file out-path rendered)
