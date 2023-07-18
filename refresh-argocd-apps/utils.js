export const mustEnv = (name) => {
    const value = process.env[name]
    if (value === undefined) throw new Error(`${name} is undefined`)
    else if (value === '') throw new Error(`${name} is empty`)

    return value
}

export const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))
