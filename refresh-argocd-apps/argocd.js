export class ArgoCDService {
    #token
    #host

    constructor(host, token) {
        this.#token = token
        this.#host = host
    }

    static async init(host, username, password) {
        const token = await ArgoCDService.#getToken(host, username, password)
        return new ArgoCDService(host, token)
    }

    static #getNoAuthHeaders(host) {
        const headers = {
            authority: host.replace('https://', ''),
            'user-agent': 'curl/7.64.1',
            'sec-fetch-site': 'same-origin'
        }

        return headers
    }

    #getHeaders() {
        const headers = ArgoCDService.#getNoAuthHeaders(this.#host)
        if (this.#token) headers['cookie'] = `argocd.token=${this.#token}`

        return headers
    }

    static async #getToken(host, username, password) {
        const response = await fetch(`${host}/api/v1/session`, {
            method: 'POST',
            headers: ArgoCDService.#getNoAuthHeaders(host),
            body: JSON.stringify({
                username: username,
                password: password
            })
        })

        if (!response.ok) throw new Error(`request failed with status ${response.status}`)

        const { token } = await response.json()
        if (!token) throw new Error('no token found in response')

        return token
    }

    async listApplications() {
        const response = await fetch(`${this.#host}/api/v1/applications?fields=items.metadata.name`, {
            method: 'GET',
            headers: this.#getHeaders()
        })

        const { items } = await response.json()

        return items.map(({ metadata }) => metadata.name)
    }

    async refreshApplication(appName) {
        const response = await fetch(`${this.#host}/api/v1/applications/${appName}?refresh=normal`, {
            method: 'GET',
            headers: this.#getHeaders()
        })

        return await response.json()
    }
}
