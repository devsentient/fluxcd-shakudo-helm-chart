# Shakudo Hyperplane Setup
1. Visit `https://your-domain.hyperplane.dev/auth/` in your browser and set up key cloak Realm first, then followed by Google SSO using the provided docs. Follow instructions in `charts/shakudo-platform/shakudo-platform-docs/Keycloak-Realm-setup.pdf`. (Note that the example uses replicant-ai as subdomain. Substitute it with your subdomain)
2. Optionally setup the Grafana and GraphQL apps by going to url `/graphql` and running the following mutations. (Substitute your subdomain)
```
mutation createGrafana {
  createPlatformApp(
    data: {
      envarIncludeKey: "INCLUDE_GRAFANA"
      appUrl: "https://grafana.<YOUR_SUBDOMAIN>.hyperplane.dev/"
      name: "Grafana Dashboard"
      tooltipDescription: "Grafana Dashboard"
      imageUrl: "https://seeklogo.com/images/G/grafana-logo-15BA0AFA8A-seeklogo.com.png"
      imageBackgroundColor: "#000000"
    }
  ) {
    id
  }
}
mutation createGraphql {
  createPlatformApp(
    data: {
      envarIncludeKey: "INCLUDE_GRAPHQL"
      appUrl: "/graphql"
      name: "GraphQL"
      tooltipDescription: "GraphQL API endpoint"
      imageUrl: "https://upload.wikimedia.org/wikipedia/commons/1/17/GraphQL_Logo.svg"
      imageBackgroundColor: "#000000"
    }
  ) {
    id
  }
}
```
