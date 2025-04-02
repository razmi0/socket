console.log("Hello, world!");

const routes = [
    {
        method: "GET",
        path: "/users/thomas/oui",
        should: "{ without_params = c.req:param() }",
    },
    {
        method: "GET",
        path: "/users/me/1",
        should: "{ with_params = c.req:param() }",
    },
    {
        method: "GET",
        path: "/query?foo=bar&baz=foo",
        should: "{ query = c.req:query() }",
    },
    {
        method: "GET",
        path: "/chain",
        should: "Hello, world!",
    },
    {
        method: "GET",
        path: "/json",
        should: "{ json = test_payload }",
    },
    {
        method: "POST",
        path: "/users",
        should: "{ post_without_params = c.req:param() }",
    },
    {
        method: "POST",
        path: "/users/me/123",
        should: "{ post_with_params = c.req:param() }",
    },
];

const mkDiv = (route, result, status, statusMsg) => {
    const result_str = typeof result === "string" ? result : JSON.stringify(result);
    return `<article id="route-${route.method}-${
        route.path
    }" style="padding: 1rem; border-radius: 1rem; border: 1px solid #ccc; margin: 1rem;">
      <h3>${route.method} ${route.path}</h3>
      <p>Should: ${route.should}<br/>
      Result : ${result_str}<br/>
      Status: ${status < 300 ? "✅" : "❌"} ${status} ${statusMsg}</p>
    </article>`;
};

const divsContainer = document.querySelector("#divs-container");

routes.forEach((route) => {
    let status = 200;
    let statusMsg = "";
    fetch(`http://localhost:8080${route.path}`, {
        method: route.method,
    })
        .then((res) => {
            status = res.status;
            statusMsg = res.statusText;
            return res.json();
        })
        .then((json) => {
            const div = mkDiv(route, json, status, statusMsg);
            divsContainer.innerHTML += div;
        })
        .catch((error) => {
            console.error(`Error fetching ${route.method} ${route.path}:`, error);
            divsContainer.innerHTML += `<article id="route-${route.method}-${route.path}" style="padding: 1rem; border-radius: 1rem; border: 1px solid red; margin: 1rem;">
        <h3>${route.method} ${route.path}</h3>
        <p>Error: Could not fetch data <br/>${error}<br/>
        Status: ${status} ${statusMsg}</p>
      </article>`;
        });
});
