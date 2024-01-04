local kubeProm = import 'kube-prometheus/main.libsonnet';

// Replace the grafana storage volume with something persistent.
local grafanaVolumes = [
  v
  for v in kubeProm.grafana.deployment.spec.template.spec.volumes
  if v.name != 'grafana-storage'
] + [
  {
    name: 'grafana-storage',
    persistentVolumeClaim: {
      claimName: 'grafana',
    },
  },
];

local kp = kubeProm {
  values+:: {
    common+: {
      namespace: 'monitoring',
    },
    prometheus+: {
      // Add to the namespaces prometheus can monitor.
      namespaces+: ['mikrotik'],
    },
  },

  prometheus+:: {
    prometheus+: {
      spec+: {
        retention: '1y',
        storage: {
          volumeClaimTemplate: {
            apiVersion: 'v1',
            kind: 'PersistentVolumeClaim',
            spec: {
              accessModes: ['ReadWriteOnce'],
              resources: {
                requests: {
                  storage: '256Gi',
                },
              },
              storageClassName: '',
              selector: {
                matchLabels: {
                  'app.kubernetes.io/name': 'prometheus',
                },
              },
            },
          },
        },
      },
    },
    pv: {
      apiVersion: 'v1',
      kind: 'PersistentVolume',
      metadata: {
        labels: {
          'app.kubernetes.io/component': 'prometheus',
          'app.kubernetes.io/name': 'prometheus',
          'app.kubernetes.io/part-of': 'kube-prometheus',
        },
        name: 'prometheus',
        namespace: 'monitoring',
      },
      spec: {
        storageClassName: '',
        capacity: {
          storage: '256Gi',
        },
        accessModes: ['ReadWriteOnce'],
        persistentVolumeReclaimPolicy: 'Retain',
        nfs: {
          path: '<volume>',
          server: '<server_ip>',
        },
        mountOptions: [
          'nfsvers=4.2',
          'hard',
          'noatime',
        ],
      },
    },
  },
  grafana+:: {
    deployment+: {
      spec+: {
        template+: {
          spec+: {
            volumes: grafanaVolumes,
          },
        },
      },
    },
    pv: {
      apiVersion: 'v1',
      kind: 'PersistentVolume',
      metadata: {
        labels: {
          'app.kubernetes.io/component': 'grafana',
          'app.kubernetes.io/name': 'grafana',
          'app.kubernetes.io/part-of': 'kube-prometheus',
        },
        name: 'grafana',
        namespace: 'monitoring',
      },
      spec: {
        storageClassName: '',
        capacity: {
          storage: '16Gi',
        },
        accessModes: ['ReadWriteOnce'],
        persistentVolumeReclaimPolicy: 'Retain',
        nfs: {
          path: '<volume>',
          server: '<server_ip>',
        },
        mountOptions: [
          'nfsvers=4.2',
          'hard',
          'noatime',
        ],
      },
    },
    pcv: {
      apiVersion: 'v1',
      kind: 'PersistentVolumeClaim',
      metadata: {
        labels: {
          'app.kubernetes.io/component': 'grafana',
          'app.kubernetes.io/name': 'grafana',
          'app.kubernetes.io/part-of': 'kube-prometheus',
        },
        name: 'grafana',
        namespace: 'monitoring',
      },
      spec: {
        storageClassName: '',
        accessModes: ['ReadWriteOnce'],
        resources: {
          requests: {
            storage: '16Gi',
          },
        },
        volumeName: 'grafana',
      },
    },
  },
};

// Generate all the manifests (taken from: https://github.com/prometheus-operator/kube-prometheus/blob/main/docs/customizing.md)
{ 'setup/0namespace-namespace': kp.kubePrometheus.namespace } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor' && name != 'prometheusRule'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor and prometheusRule are separated so that they can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ 'prometheus-operator-prometheusRule': kp.prometheusOperator.prometheusRule } +
{ 'kube-prometheus-prometheusRule': kp.kubePrometheus.prometheusRule } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['blackbox-exporter-' + name]: kp.blackboxExporter[name] for name in std.objectFields(kp.blackboxExporter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['kubernetes-' + name]: kp.kubernetesControlPlane[name] for name in std.objectFields(kp.kubernetesControlPlane) }
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) }
