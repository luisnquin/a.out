#!/usr/bin/env node

import chalk from 'chalk'

import { ArgoCDService } from './argocd.js'
import { sleep, mustEnv } from './utils.js'

const ARGOCD_USERNAME = mustEnv('ARGOCD_USERNAME')
const ARGOCD_PASSWORD = mustEnv('ARGOCD_PASSWORD')
const ARGOCD_HOST = mustEnv('ARGOCD_HOST')

const main = async () => {
    console.log(chalk.yellowBright('initializing ArgoCD service...'))

    const argoCDService = await ArgoCDService.init(ARGOCD_HOST, ARGOCD_USERNAME, ARGOCD_PASSWORD)

    const apps = await argoCDService.listApplications()

    console.log(chalk.blueBright(`${apps.length} applications will be refreshed...`))
    await sleep(3500)

    const results = []
    const refreshOperations = {}
    const usedRevisions = []

    const refreshApplication = async (appName) => {
        const { status } = await argoCDService.refreshApplication(appName)
        const { resources, history } = status

        const resourceNames = resources.filter((r) => r.kind === 'Service').map((r) => r.name)

        const [before, after] = history.filter((_, i) => i >= history.length - 2)
        const currentRev = after.revision.slice(0, 8)

        const nowUTC = new Date(new Date().toUTCString())
        nowUTC.setUTCSeconds(nowUTC.getUTCSeconds() - 5)

        const deployedAt = new Date(after.deployedAt)

        if (!usedRevisions.some((rev) => rev === currentRev)) {
            usedRevisions.push(currentRev)
        }

        return {
            app: appName,
            resources: resourceNames.join(', '),
            changes: `${before.id} => ${after.id}`,
            hadEffect: deployedAt > nowUTC
        }
    }

    const handleRefreshOperation = async (appName) => {
        refreshOperations[appName] = { start: new Date() }

        const result = await refreshApplication(appName, argoCDService)
        results.push(result)

        refreshOperations[appName].end = new Date()
    }

    const displayOperationTimes = () => {
        console.clear()
        process.stdout.write('\n')

        for (const appName in refreshOperations) {
            const operation = refreshOperations[appName]

            let startTime = operation.start
            let endTime = operation.end ? operation.end : new Date()

            const elapsed = startTime ? endTime - startTime : 0

            let elapsedText

            if (elapsed > 8000) {
                elapsedText = chalk.redBright(elapsed + 'ms')
            } else if (elapsed > 5000) {
                elapsedText = chalk.yellowBright(elapsed + 'ms')
            } else {
                elapsedText = chalk.greenBright(elapsed + 'ms')
            }

            console.log(`${elapsedText} ${chalk.magentaBright(':::::::>')} ${appName}`)
        }
    }

    const timerInterval = setInterval(displayOperationTimes, 100)

    // TODO: report if a promise(operation) ended in an error
    await Promise.allSettled(apps.map(handleRefreshOperation)).then(() => {
        clearInterval(timerInterval)
        console.log(chalk.bold('\nAll requests completed.'))
    })

    if (results.length > 0) {
        console.log('used revisions: ' + usedRevisions.join(', '))
        console.table(results)
    } else {
        console.log('no results')
    }
}

import esMain from 'es-main'

if (esMain(import.meta)) {
    await main()
}
