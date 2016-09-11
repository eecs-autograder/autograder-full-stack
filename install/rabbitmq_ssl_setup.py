import argparse
import os


def main():
    args = parse_args()
    lets_encrypt_path = os.path.join(
        '/etc/letsencrypt/live/', args.full_domain)
    rendered = rabbitmq_conf_tmpl.format(domain=lets_encrypt_path)
    with open('/etc/rabbitmq/rabbitmq.config', 'w') as f:
        f.write(rendered)
    # print(rendered)

    print('To reload the config file:',
          'sudo rabbitmqctl stop',
          'sudo rabbitmq-server -detached',
          'sudo rabbitmqctl status')


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("full_domain")

    return parser.parse_args()


rabbitmq_conf_tmpl = '''
[
    {{
        rabbit, [
            {{ssl_listeners, [5671]}},
            {{
                ssl_options, [
                    {{cacertfile, "{domain}/fullchain.pem"}},
                    {{certfile, "{domain}/cert.pem"}},
                    {{keyfile, "{domain}/key.pem"}},
                    {{verify, verify_peer}},
                    {{fail_if_no_peer_cert, true}}
                ]
            }}
        ]
    }},
    {{
        rabbitmq_management, [
            {{listener, [{{port, 15672}}, {{ssl, true}}]}}
        ]
    }}
].
'''


if __name__ == '__main__':
    main()
